import sys
import os

class Scanner:
    digits = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9']
    hexdigits = digits.copy()
    hexdigits.extend(['a', 'b', 'c', 'd', 'e', 'f'])
    hexleader = '$'
    whitespace = [' ', '\t']
    commentlead = ';'
    labellead = ':'
    modifiers = ['<', '>']
    alpha = [chr(c) for c in range(ord('A'), ord('Z') + 1)]
    alpha = alpha + [c.lower() for c in alpha]
    identifier_start = alpha + ['_']
    identifier_mid = alpha + ['_'] + digits 
    registers = [chr(c) for c in range(ord('A'), ord('G') + 1)]
    registers = registers + [c.lower() for c in registers]

    @staticmethod
    def scan_literal_value(line, pos):
        collected = ''
        state = 'seen_nothing'
        radix = 10
        modifier = None
        for index, c in enumerate(line[pos:]):
            if state == 'seen_nothing' or state == 'seen_modifier':
                if c in Scanner.whitespace: continue
                elif c == Scanner.hexleader:
                    state = 'start_hex'
                    radix = 16
                    continue
                elif c in Scanner.digits:
                    collected += c
                    state = 'collect_dec'
                    continue
                elif c in Scanner.modifiers:
                    if modifier:
                        state = 'abort'    # cannot accept multiple modifiers
                        break
                    else:
                        modifier = c
                        state = 'seen_modifier'
                else:
                    state = 'abort'
                    break
            elif state == 'start_hex':
                if c in Scanner.hexdigits:
                    collected += c
                    state = 'collect_hex'
                    continue
                else:
                    state = 'abort'
                    break
            elif state == 'collect_hex':
                if c in Scanner.hexdigits:
                    collected += c
                    state = 'collect_hex'
                    continue
                elif c == Scanner.commentlead:
                    state = 'finished'
                    break
                elif c in Scanner.whitespace:
                    state = 'finished'
                    break
                else:
                    state = 'abort'
                    break
            elif state == 'collect_dec':
                if c in Scanner.digits:
                    collected += c
                    state = 'collect_dec'
                    continue
                elif c == Scanner.commentlead:
                    state = 'finished'
                    break
                elif c in Scanner.whitespace:
                    state = 'finished'
                    break
                else:
                    state = 'abort'
                    break
        else:
            if state.startswith('collect'):
                state = 'finished'
                index += 1
        if state == 'finished' and len(collected):
            value = int(collected, radix)
            if modifier == '<':
                value = value & 0xff
            elif modifier == '>':
                value = int(value / 256)
            return True, value, pos + index, state
        return False, 0, pos + index, state

    @staticmethod
    def scan_identifier(line, pos):
        collected = ''
        state = 'seen_nothing'
        modifier = None

        for index, c in enumerate(line[pos:]):
            # print(state, f'|{c}|')
            if state == 'seen_nothing' or state == 'seen_modifier':
                if c in Scanner.whitespace: continue
                elif c in Scanner.identifier_start:
                    collected += c
                    state = 'collect'
                elif c in Scanner.modifiers:
                    if modifier:
                        state = 'abort'
                        break
                    else:
                        modifier = c
                        state = 'seen_modifier'
                else:
                    state = 'abort'
                    break
            elif state == 'collect':
                if c in Scanner.identifier_mid:
                    collected += c
                elif c in Scanner.commentlead:
                    state = 'finished'
                    break
                elif c in Scanner.whitespace:
                    state = 'finished'
                    break
                else:
                    state = 'abort'
                    break
        else:
            state = 'finished'
            index += 1

        if state == 'finished' and len(collected):
            return True, collected, modifier, pos + index, state
        return False, None, None, pos + index, state


    @staticmethod
    def test_scan_literal():
        error = False
        lines = [
                ("  $", False, 0),
                ("   $1234 ", True, 0x1234),
                (" 1234 ", True, 1234),
                ("12 ;  34", True, 12),
                (" $ab;cd", True, 0xab),
                ("lda", False, 0),
                ("  hello", False, 0),
                ("12ab", False, 0),
                ("$12ab", True, 0x12ab),
                (" < $12ab", True, 0xab),
                (" >$12ab", True, 0x12),
                ]
        for line, expected_ret, expected_value in lines:
            ret, val, _ , state = Scanner.scan_literal_value(line, 0)
            if ret == expected_ret and val == expected_value:
                print(f'{line+"|":20s} : {ret}, {val} : OK')
            else:
                print(f'{line+"|":20s} : {ret}, {val} : NOT OK ({state}) NOT {expected_ret}, {expected_value}')
                error = True
        return error

    @staticmethod
    def test_scan_identifier():
        error = False
        lines = [
                (' hello world', True, 'hello', None),
                (' <hello world', True, 'hello', '<'),
                ('   >_org', True, '_org', '>'),
                ('kali_linux__1_24', True, 'kali_linux__1_24', None),
                ('> love_caro; every day', True, 'love_caro', '>'),
                ('  > >_org', False, None, None),
                ('  < _org>', False, None, None),
                ('  < _org$', False, None, None),
                ]
        for line, expected_ret, expected_value, expected_mod in lines:
            ret, val, mod, _, state = Scanner.scan_identifier(line, 0)
            if ret == expected_ret and val == expected_value and mod == expected_mod:
                print(f'{line+"|":20s} : {ret}, {val}, {mod} : OK')
            else:
                error = True
                print(f'{line+"|":20s} : {ret}, {val}, {mod} : NOT OK ({state}) NOT {expected_ret}, {expected_value}, {expected_mod}')
        return error
                
    @staticmethod
    def scan_for_org(line, pos):
        state = 'seen_nothing'

        for index, c in enumerate(line[pos:]):
            # print(state, f'|{c}|')
            if state == 'seen_nothing':
                if c.lower() == 'o':
                    state = 'seen_o'
                elif c in Scanner.whitespace:
                    continue
                else:
                    state = 'abort'
                    break
            elif state == 'seen_o':
                if c.lower() == 'r':
                    state = 'seen_r'
                else:
                    state = 'abort'
                    break
            elif state == 'seen_r':
                if c.lower() == 'g':
                    state = 'seen_g'
                else:
                    state = 'abort'
                    break
            elif state == 'seen_g':
                if c in Scanner.whitespace:
                    state = 'seen_org_whitespace'
                    continue
                else:
                    state = 'abort'
                    break
            elif state == 'seen_org_whitespace':
                ok, value, _, _ = Scanner.scan_literal_value(line, index)
                if not ok:
                    state = 'abort'
                    break
                else:
                    return True, value
        return False, None

    @staticmethod
    def test_org():
        error = False
        lines = [
                (" org $", False, None),
                (" org  $1234 ", True, 0x1234),
                (" org 1234 ", True, 1234),
                ("org  12 ;  34", True, 12),
                ("org  $ab;cd", True, 0xab),
                ("org lda", False, None),
                ("org   hello", False, None),
                ("12ab", False, None),
                ("org $12ab", True, 0x12ab),
                ("org  < $12ab", True, 0xab),
                ("org  >$12ab", True, 0x12),
                ("org>$12ab", False, None),
                ("org$ab;cd", False, None),
                ]
        for line, expected_ret, expected_value in lines:
            ret, val = Scanner.scan_for_org(line, 0)
            if ret == expected_ret and val == expected_value:
                print(f'{line+"|":20s} : {ret}, {val} : OK')
            else:
                print(f'{line+"|":20s} : {ret}, {val} : NOT OK,  NOT {expected_ret}, {expected_value}')
                error = True
        return error


    @staticmethod
    def scan_for_label(line, pos):
        state = 'seen_nothing'
        identifier = None
        afterpos = 0
        for index, c in enumerate(line[pos:]):
            # print(state, f'|{c}|')
            if state == 'seen_nothing':
                if c in Scanner.whitespace: continue
                elif c == Scanner.labellead:
                    state = 'seen_colon'
                else:
                    state = 'abort'
                    break
            elif state == 'seen_colon':
                ok, identifier, modifier, afterpos, _ = Scanner.scan_identifier(line, index)
                if not ok:
                    state = 'abort'
                    break
                elif modifier is not None:
                    state = 'abort'
                    break
                else:
                    state = 'after_label'
                    break
        else:
            state = 'finished'


        if state == 'after_label':
            for index, c in enumerate(line[afterpos+1:]):
                # print(state, f'>|{c}|')
                if c in Scanner.whitespace: continue
                elif c == Scanner.commentlead:
                    state = 'finished'
                    break
                else:
                    state = 'abort'
                    break
            else:
                state = 'finished'
        if identifier and state == 'finished':
            return True, identifier
        return False, None


    @staticmethod
    def test_label():
        lines = [
                (":label   12 ;  34", False, None),
                (":label", True, 'label'),
                (":label ", True, 'label'),
                (":label 1", False, None),
                (":la$el", False, None),
                ]
        error = False
        for line, expected_ret, expected_value in lines:
            ret, val = Scanner.scan_for_label(line, 0)
            if ret == expected_ret and val == expected_value:
                print(f'{line+"|":20s} : {ret}, {val} : OK')
            else:
                error = True
                print(f'{line+"|":20s} : {ret}, {val} : NOT OK,  NOT {expected_ret}, {expected_value}')
        return error


    @staticmethod
    def scan_for_condition(line, pos):
        state = 'seen_nothing'
        condition = 'un'
        afterpos = None
        index = 0
        for index, c in enumerate(line[pos:]):
            c = c.lower()
            # print(state, f'|{c}|')
            if state == 'seen_nothing':
                if c in Scanner.whitespace: 
                    continue
                elif c == ':':
                    state = 'seen_colon'
                    # if there is a colon, we expect an implicit condition
                    condition = None
                elif c == Scanner.commentlead:
                    state = 'finished'
                    break
                else:
                    state = 'abort'
                    break
            elif state == 'seen_colon':
                if c == 'e':
                    state = 'seen_e'
                elif c == 'g':
                    state = 'seen_g'
                elif c == 's':
                    state = 'seen_s'
                elif c in Scanner.whitespace:
                    continue
                else:
                    state = 'abort'
                    break
            elif state == 'seen_e':
                if c == 'q':
                    state = 'after_condition'
                    condition = 'eq'
                    break
                else:
                    state = 'abort'
                    break
            elif state == 'seen_g':
                if c == 't':
                    state = 'after_condition'
                    condition = 'gt'
                    break
                else:
                    state = 'abort'
                    break
            elif state == 'seen_s':
                if c == 'm':
                    state = 'after_condition'
                    condition = 'sm'
                    break
                else:
                    state = 'abort'
                    break
        else:
            state = 'finished'

        if state == 'after_condition':
            # print('after', condition, ':', f'"{line[afterpos:]}"')
            afterpos = pos + index + 1
            for index, c in enumerate(line[afterpos:]):
                # print(state, f'>|{c}|')
                if c in Scanner.whitespace: continue
                elif c == Scanner.commentlead:
                    state = 'finished'
                    break
                else:
                    state = 'abort'
                    break
            else:
                state = 'finished'
        if state == 'finished' and condition:
            return True, condition
        return False, None

    @staticmethod
    def test_condition():
        lines = [
                (":label   12 ;  34", False, None),
                (":eq", True, 'eq'),
                (" : eq ", True, 'eq'),
                (" : eq", True, 'eq'),
                (" : eq ; equal", True, 'eq'),
                (":gt", True, 'gt'),
                (" : gt ", True, 'gt'),
                (" : gt ; gtual", True, 'gt'),
                (":sm", True, 'sm'),
                (" : sm ", True, 'sm'),
                (" : sm ; smual", True, 'sm'),
                (";", True, 'un'),  # implicit
                (" ", True, 'un'),  # implicit
                (" : eq_1", False, None),
                (": eq 1", False, None),
                ]
        error = False
        for line, expected_ret, expected_value in lines:
            ret, val = Scanner.scan_for_condition(line, 0)
            if ret == expected_ret and val == expected_value:
                print(f'{line+"|":20s} : {ret}, {val} : OK')
            else:
                error = True
                print(f'{line+"|":20s} : {ret}, {val} : NOT OK,  NOT {expected_ret}, {expected_value}')
        return error

    @staticmethod
    def scan_for_comma(line, pos):
        state = 'seen_nothing'
        commapos = None
        for index, c in enumerate(line[pos:]):
            # print(state, f'|{c}|')
            if state == 'seen_nothing':
                if c in Scanner.whitespace:
                    continue
                elif c == ',':
                    state = 'finished'
                    commapos = pos + index
                    break
                else:
                    state = 'abort'
                    break
        if state == 'finished':
            return True, commapos
        return False, None

    @staticmethod
    def test_comma():
        lines = [
                (":la$el", False, None),
                ("", False, None),
                ("   ", False, None),
                ("  a", False, None),
                (" , ", True, 1),
                ("  ,", True, 2),
                ]
        error = False
        for line, expected_ret, expected_value in lines:
            ret, val = Scanner.scan_for_comma(line, 0)
            if ret == expected_ret and val == expected_value:
                print(f'{line+"|":20s} : {ret}, {val} : OK')
            else:
                error = True
                print(f'{line+"|":20s} : {ret}, {val} : NOT OK,  NOT {expected_ret}, {expected_value}')
        return error

    @staticmethod
    def scan_for_reg(line, pos, leading_whitespace=False):
        state = 'seen_nothing'
        reg_pos = None
        register = None

        for index, c in enumerate(line[pos:]):
            c = c.lower()
            # print(state, f'|{c}|')
            if state == 'seen_nothing':
                if leading_whitespace:
                    if c in Scanner.whitespace: 
                        continue
                if c in Scanner.registers:
                    register = c
                    reg_pos = pos + index
                    state = 'finished'
                    break
                else:
                    state = 'abort'
                    break
        if state == 'finished':
            return True, register, reg_pos
        return False, None, None

    @staticmethod
    def test_reg_nolead():
        lines = [
                ("a asf", True, 'a', 0),
                ("a", True, 'a', 0),
                (" a", False, None, None),
                ("xa", False, None, None),
                ]
        error = False
        for line, expected_ret, expected_value, expected_pos in lines:
            ret, val, pos = Scanner.scan_for_reg(line, 0, False)
            if ret == expected_ret and val == expected_value and pos == expected_pos:
                print(f'{line+"|":20s} : {ret}, {val} : OK')
            else:
                error = True
                print(f'{line+"|":20s} : {ret}, {val} : NOT OK,  NOT {expected_ret}, {expected_value}')
        return error

    @staticmethod
    def test_reg_leading_spaces():
        lines = [
                ("a asf", True, 'a', 0),
                ("a", True, 'a', 0),
                (" a", True, 'a', 1),
                ("xa", False, None, None),
                ]
        error = False
        for line, expected_ret, expected_value, expected_pos in lines:
            ret, val, pos = Scanner.scan_for_reg(line, 0, True)
            if ret == expected_ret and val == expected_value and pos == expected_pos:
                print(f'{line+"|":20s} : {ret}, {val} : OK')
            else:
                error = True
                print(f'{line+"|":20s} : {ret}, {val} : NOT OK,  NOT {expected_ret}, {expected_value}')
        return error


    @staticmethod
    def scan_for_immediate(line, pos):
        state = 'seen_nothing'
        immpos = None
        for index, c in enumerate(line[pos:]):
            # print(state, f'|{c}|')
            if state == 'seen_nothing':
                if c in Scanner.whitespace:
                    continue
                elif c == '#':
                    state = 'finished'
                    immpos = pos + index
                    break
                else:
                    state = 'abort'
                    break
        if state == 'finished':
            return True, immpos
        return False, None

    @staticmethod
    def test_immediate():
        lines = [
                (":la$el", False, None),
                ("", False, None),
                ("   ", False, None),
                ("  a", False, None),
                (" # ", True, 1),
                ("  #", True, 2),
                ]
        error = False
        for line, expected_ret, expected_value in lines:
            ret, val = Scanner.scan_for_immediate(line, 0)
            if ret == expected_ret and val == expected_value:
                print(f'{line+"|":20s} : {ret}, {val} : OK')
            else:
                error = True
                print(f'{line+"|":20s} : {ret}, {val} : NOT OK,  NOT {expected_ret}, {expected_value}')
        return error

    @staticmethod
    def scan_for_jmp(line, pos):
        state = 'seen_nothing'
        addr = None
        addrpos = None
        condition = None
        modifier = None
        for index, c in enumerate(line[pos:]):
            c = c.lower()
            # print(state, f'|{c}|')
            if state == 'seen_nothing':
                if c in Scanner.whitespace: 
                    continue
                elif c == 'j':
                    state = 'seen_j'
                else:
                    state = 'abort'
                    break
            elif state == 'seen_j':
                if c == 'm':
                    state = 'seen_jm'
                else:
                    state = 'abort'
                    break
            elif state == 'seen_jm':
                if c == 'p':
                    state = 'seen_jmp'
                else:
                    state = 'abort'
                    break
            elif state == 'seen_jmp':
                if c in Scanner.whitespace:
                    state = 'seen_jmp_white'
                    # print(state)
                    # test for identifier
                    ok, addr, modifier, addrpos, _ = Scanner.scan_identifier(line, pos + index)
                    if ok:
                        state = 'got_address'
                    else:
                        # else test for literal
                        ok, addr, addrpos, _ = Scanner.scan_literal_value(line, pos + index)
                        if ok:
                            state = 'got_address'
                        else:
                            state = 'abort'
                            break
                else:
                    state = 'abort'
                    break
            elif state == 'got_address':
                # print(f'addr={addr}')
                # print(f'line[addrpos:]="{line[addrpos:]}"')
                # test for condition
                ok, condition = Scanner.scan_for_condition(line, addrpos)
                # print('cond', ok, condition)
                if ok:
                    state = 'finished'
                    break
                else:
                    state = 'abort'
                    break

        if state == 'finished':
            return True, addr, modifier, condition
        return False, None, None, None
                

    @staticmethod
    def test_jmp():
        lines = [
                (":label   12 ;  34", False, None, None),
                ("jmp 0 :eq", True, 0, 'eq'),
                ("jmp $000a:eq", False, None, None),
                ("jmp $000a : eq", True, 0xa, 'eq'),
                ("jmp lbl : eq", True, 'lbl', 'eq'),
                ("jmp $000a", True, 0xa, 'un'),
                ("jmp label ; jump there : eq", True, 'label', 'un'),
                ("jmp label man", False, None, None),
                ("jmp $67 man : eq", False, None, None),
                ("jmp $67 nan ", False, None, None),
                ]
        error = False
        for line, expected_ret, expected_value, expected_cond in lines:
            ret, val, _, cond = Scanner.scan_for_jmp(line, 0)
            if ret == expected_ret and val == expected_value and cond == expected_cond:
                print(f'{line+"|":20s} : {ret}, {val}, {cond} : OK')
            else:
                error = True
                print(f'{line+"|":20s} : {ret}, {val}, {cond} : NOT OK,  NOT {expected_ret}, {expected_value}, {expected_cond}')
        return error

    @staticmethod
    def scan_for_ld(line, pos):
        pass
        state = 'seen_nothing'
        register = None
        addr = None
        modifier = None
        addrmode = None
        regpos = None
        condition = None
        immipos = None
        for index, c in enumerate(line[pos:]):
            c = c.lower()
            print(state, f'|{c}|')
            if state == 'seen_nothing':
                if c in Scanner.whitespace: 
                    continue
                elif c == 'l':
                    state = 'seen_l'
                else:
                    state = 'abort'
                    break
            elif state == 'seen_l':
                if c == 'd':
                    state = 'seen_ld'
                else:
                    state = 'abort'
                    break
            elif state == 'seen_ld':
                ok, register, reg_pos, = Scanner.scan_for_reg(line, pos + index)
                if ok:
                    # test for immediate
                    ok, immipos = Scanner.scan_for_immediate(line, reg_pos + 1)
                    if ok:
                        # load register with immediate value
                        addrmode = 'immediate'
                        reg_pos = immipos
                    else:
                        addrmode = 'absolute'

                    reg_pos += 1
                    # test for identifier
                    ok, addr, modifier, addrpos, _ = Scanner.scan_identifier(line, reg_pos)
                    if ok:
                        state = 'got_address'
                    else:
                        # else test for literal
                        ok, addr, addrpos, _ = Scanner.scan_literal_value(line, reg_pos)
                        if ok:
                            state = 'got_address'
                        else:
                            state = 'abort'
                            break
            elif state == 'got_address':
                print(f'addr={addr}')
                print(f'line[addrpos:]="{line[addrpos:]}"')
                # test for condition
                ok, condition = Scanner.scan_for_condition(line, addrpos)
                print('cond', ok, condition)
                if ok:
                    state = 'finished'
                    break
                else:
                    state = 'abort'
                    break

        if state == 'finished':
            return True, register, addrmode, addr, modifier, condition
        return False, None, None, None, None, None

    @staticmethod
    def test_ld():
        lines = [
                (":label   12 ;  34", False, None, None, None, None, None),
                ("lda #0 :eq", True, 'a', 'immediate', 0, None, 'eq'),
                ("lda $0 :eq", True, 'a', 'absolute', 0, None, 'eq'),
                ("lda #0", True, 'a', 'immediate', 0, None, 'un'),
                ("lda $0", True, 'a', 'absolute', 0, None, 'un'),
                ("lda #<addr", True, 'a', 'immediate', 'addr', '<', 'un'),
                ("lda $>addr",False, None, None, None, None, None),
                ("lda >addr", True, 'a', 'absolute', 'addr', '>', 'un'),
                ("lda #<addr :sm", True, 'a', 'immediate', 'addr', '<', 'sm'),
                ("lda $>addr :sm", False, None, None, None, None, None),
                ("lda >addr :sm", True, 'a', 'absolute', 'addr', '>', 'sm'),
                ]
        error = False
        for line, ea, eb, ec, ed, ee, ef in lines:
            a, b, c, d, e, f = Scanner.scan_for_ld(line, 0)
            if a == ea and b == eb and c == ec and d == ed and e == ee and f == ef:
                print(f'{line+"|":20s} : {a,b,c,d,e,f} : OK')
            else:
                error = True
                print(f'{line+"|":20s} : {a,b,c,d,e,f}, : NOT OK,  NOT {ea, eb, ec, ed, ee, ef}')
        return error

    @staticmethod
    def scan_for_st(line, pos):
        pass
   
    @staticmethod
    def scan_for_in(line, pos):
        pass

    @staticmethod
    def scan_for_out(line, pos):
        pass


    @staticmethod
    def test():
        ret = Scanner.test_scan_literal()
        ret = ret or Scanner.test_scan_identifier()
        ret = ret or Scanner.test_org()
        ret = ret or Scanner.test_label()
        ret = ret or Scanner.test_condition()
        ret = ret or Scanner.test_comma()
        ret = ret or Scanner.test_reg_nolead()
        ret = ret or Scanner.test_reg_leading_spaces()
        ret = ret or Scanner.test_immediate()
        ret = ret or Scanner.test_jmp()
        ret = ret or Scanner.test_ld()
        if ret:
            print('THERE WERE ERRORS')
        else:
            print('NO ERRORS')


class SymbolTable:
    def __init__(self):
        self.symbols = {}

    def get(self, key):
        if isinstance(str, key):
            return self.symbols.get(key, 0)
        else:
            return key

    def put(self, key, value):
        self.symbols[key] = value



class Asm:
    def __init__(self):
        self.symboltable = SymbolTable()
        self.mem = {}
        self.pc = 0
        self.max_pc = 0

if __name__ == '__main__':
    Scanner.test()

