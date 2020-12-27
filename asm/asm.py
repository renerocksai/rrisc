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
        """-> ok: bool, value:int, posafter: int, state:str"""
        collected = ''
        state = 'seen_nothing'
        radix = 10
        modifier = None
        index = 0
        for index, c in enumerate(line[pos:]):
            c = c.lower()
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
        """-> ok: bool, identifier:str, modifier:str, posafter: int, state:str"""
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
        """-> ok: bool, value:int"""
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
        """-> ok: bool, label:str"""
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
        """-> ok:bool, condition:str ('un', 'eq', 'gt', 'sm')"""
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
        """-> ok:bool, commapos:int"""
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
        """-> ok:bool, register:str, reg_pos:int"""
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
        """-> ok:bool, immpos:int (pos of # char)"""
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
        """-> ok:bool, addr:str|int, modifier:str, condition:str"""
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

        # TODO : handle JMP HI[LO]
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
        """-> ok:bool, register:str, addrmode:str, addr:str|int, modifier:str, condition:str"""
        state = 'seen_nothing'
        register = None
        addr = None
        modifier = None
        addrmode = None
        reg_pos = None
        condition = None
        immipos = None
        for index, c in enumerate(line[pos:]):
            c = c.lower()
            #0 print(state, f'|{c}|')
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
                #0 print(f'addr={addr}')
                #0 print(f'line[addrpos:]="{line[addrpos:]}"')
                # test for condition
                ok, condition = Scanner.scan_for_condition(line, addrpos)
                #0 print('cond', ok, condition)
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
        """-> ok:bool, register:str, addrmode:str, addr:str|int, modifier:str, condition:str"""
        state = 'seen_nothing'
        register = None
        addr = None
        modifier = None
        addrmode = None
        reg_pos = None
        condition = None
        for index, c in enumerate(line[pos:]):
            c = c.lower()
            #0 print(state, f'|{c}|')
            if state == 'seen_nothing':
                if c in Scanner.whitespace: 
                    continue
                elif c == 's':
                    state = 'seen_s'
                else:
                    state = 'abort'
                    break
            elif state == 'seen_s':
                if c == 't':
                    state = 'seen_st'
                else:
                    state = 'abort'
                    break
            elif state == 'seen_st':
                ok, register, reg_pos, = Scanner.scan_for_reg(line, pos + index)
                if ok:
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
                #0 print(f'addr={addr}')
                #0 print(f'line[addrpos:]="{line[addrpos:]}"')
                # test for condition
                ok, condition = Scanner.scan_for_condition(line, addrpos)
                #0 print('cond', ok, condition)
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
    def test_st():
        lines = [
                (":label   12 ;  34", False, None, None, None, None, None),
                ("sta #0 :eq",  False, None, None, None, None, None),
                ("sta $0 :eq", True, 'a', 'absolute', 0, None, 'eq'),
                ("sta #0",  False, None, None, None, None, None),
                ("sta $0", True, 'a', 'absolute', 0, None, 'un'),
                ("sta #<addr",  False, None, None, None, None, None),
                ("sta $>addr",False, None, None, None, None, None),
                ("sta >addr", True, 'a', 'absolute', 'addr', '>', 'un'),
                ("sta #<addr :sm",  False, None, None, None, None, None),
                ("sta $>addr :sm", False, None, None, None, None, None),
                ("sta >addr :sm", True, 'a', 'absolute', 'addr', '>', 'sm'),
                ]
        error = False
        for line, ea, eb, ec, ed, ee, ef in lines:
            a, b, c, d, e, f = Scanner.scan_for_st(line, 0)
            if a == ea and b == eb and c == ec and d == ed and e == ee and f == ef:
                print(f'{line+"|":20s} : {a,b,c,d,e,f} : OK')
            else:
                error = True
                print(f'{line+"|":20s} : {a,b,c,d,e,f}, : NOT OK,  NOT {ea, eb, ec, ed, ee, ef}')
        return error

   
    @staticmethod
    def scan_for_in(line, pos):
        """-> ok:bool, register:str, addrmode:str, addr:str|int, modifier:str, condition:str"""
        state = 'seen_nothing'
        register = None
        addr = None
        modifier = None
        addrmode = None
        reg_pos = None
        condition = None
        commapos = None
        for index, c in enumerate(line[pos:]):
            c = c.lower()
            #0 print(state, f'|{c}|')
            if state == 'seen_nothing':
                if c in Scanner.whitespace: 
                    continue
                elif c == 'i':
                    state = 'seen_i'
                else:
                    state = 'abort'
                    break
            elif state == 'seen_i':
                if c == 'n':
                    state = 'seen_in'
                else:
                    state = 'abort'
                    break
            elif state == 'seen_in':
                ok, register, reg_pos, = Scanner.scan_for_reg(line, pos + index, True)
                if ok:
                    addrmode = 'extern'
                    reg_pos += 1
                    ok, commapos = Scanner.scan_for_comma(line, reg_pos)
                    if ok:
                        commapos += 1
                    # test for identifier
                    ok, addr, modifier, addrpos, _ = Scanner.scan_identifier(line, commapos)
                    if ok:
                        state = 'got_address'
                    else:
                        # else test for literal
                        ok, addr, addrpos, _ = Scanner.scan_literal_value(line, commapos)
                        if ok:
                            state = 'got_address'
                        else:
                            state = 'abort'
                            break
            elif state == 'got_address':
                #0 print(f'addr={addr}')
                #0 print(f'line[addrpos:]="{line[addrpos:]}"')
                # test for condition
                ok, condition = Scanner.scan_for_condition(line, addrpos)
                #0 print('cond', ok, condition)
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
    def test_in():
        lines = [
                (":label   12 ;  34", False, None, None, None, None, None),
                ("in a, #0 :eq",  False, None, None, None, None, None),
                ("in a, $0 :eq", True, 'a', 'extern', 0, None, 'eq'),
                ("in a, #0",  False, None, None, None, None, None),
                ("in a, $0", True, 'a', 'extern', 0, None, 'un'),
                ("in a, #<addr",  False, None, None, None, None, None),
                ("in a, $>addr",False, None, None, None, None, None),
                ("in a, >addr", True, 'a', 'extern', 'addr', '>', 'un'),
                ("in a, #<addr :sm",  False, None, None, None, None, None),
                ("in a, $>addr :sm", False, None, None, None, None, None),
                ("in a, >addr :sm", True, 'a', 'extern', 'addr', '>', 'sm'),
                ]
        error = False
        for line, ea, eb, ec, ed, ee, ef in lines:
            a, b, c, d, e, f = Scanner.scan_for_in(line, 0)
            if a == ea and b == eb and c == ec and d == ed and e == ee and f == ef:
                print(f'{line+"|":20s} : {a,b,c,d,e,f} : OK')
            else:
                error = True
                print(f'{line+"|":20s} : {a,b,c,d,e,f}, : NOT OK,  NOT {ea, eb, ec, ed, ee, ef}')
        return error


    @staticmethod
    def scan_for_out(line, pos):
        """-> ok:bool, register:str, addrmode:str, addr:str|int, modifier:str, condition:str"""
        state = 'seen_nothing'
        register = None
        addr = None
        modifier = None
        addrmode = None
        reg_pos = None
        condition = None
        commapos = None
        for index, c in enumerate(line[pos:]):
            c = c.lower()
            #0 print(state, f'|{c}|')
            if state == 'seen_nothing':
                if c in Scanner.whitespace: 
                    continue
                elif c == 'o':
                    state = 'seen_o'
                else:
                    state = 'abort'
                    break
            elif state == 'seen_o':
                if c == 'u':
                    state = 'seen_ou'
                else:
                    state = 'abort'
                    break
            elif state == 'seen_ou':
                if c == 't':
                    state = 'seen_out'
                else:
                    state = 'abort'
                    break
            elif state == 'seen_out':
                ok, register, reg_pos, = Scanner.scan_for_reg(line, pos + index, True)
                if ok:
                    addrmode = 'extern'
                    reg_pos += 1
                    ok, commapos = Scanner.scan_for_comma(line, reg_pos)
                    if ok:
                        commapos += 1
                    # test for identifier
                    ok, addr, modifier, addrpos, _ = Scanner.scan_identifier(line, commapos)
                    if ok:
                        state = 'got_address'
                    else:
                        # else test for literal
                        ok, addr, addrpos, _ = Scanner.scan_literal_value(line, commapos)
                        if ok:
                            state = 'got_address'
                        else:
                            state = 'abort'
                            break
            elif state == 'got_address':
                #0 print(f'addr={addr}')
                #0 print(f'line[addrpos:]="{line[addrpos:]}"')
                # test for condition
                ok, condition = Scanner.scan_for_condition(line, addrpos)
                #0 print('cond', ok, condition)
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
    def test_out():
        lines = [
                (":label   12 ;  34", False, None, None, None, None, None),
                ("out a, #0 :eq",  False, None, None, None, None, None),
                ("out a, $0 :eq", True, 'a', 'extern', 0, None, 'eq'),
                ("out a, #0",  False, None, None, None, None, None),
                ("out a, $0", True, 'a', 'extern', 0, None, 'un'),
                ("out a, #<addr",  False, None, None, None, None, None),
                ("out a, $>addr",False, None, None, None, None, None),
                ("out a, >addr", True, 'a', 'extern', 'addr', '>', 'un'),
                ("out a, #<addr :sm",  False, None, None, None, None, None),
                ("out a, $>addr :sm", False, None, None, None, None, None),
                ("out a, >addr :sm", True, 'a', 'extern', 'addr', '>', 'sm'),
                ]
        error = False
        for line, ea, eb, ec, ed, ee, ef in lines:
            a, b, c, d, e, f = Scanner.scan_for_out(line, 0)
            if a == ea and b == eb and c == ec and d == ed and e == ee and f == ef:
                print(f'{line+"|":20s} : {a,b,c,d,e,f} : OK')
            else:
                error = True
                print(f'{line+"|":20s} : {a,b,c,d,e,f}, : NOT OK,  NOT {ea, eb, ec, ed, ee, ef}')
        return error


    @staticmethod
    def scan_for_jmpp(line, pos):
        pass

    @staticmethod
    def scan_for_skipline(line):
        """-> ok:bool"""
        if len(line) == 0:
            return True
        state = 'seen_nothing'
        for c in line:
            if state == 'seen_nothing':
                if c in Scanner.whitespace:
                    continue
                elif c == Scanner.commentlead:
                    state = 'finished'
                    break
                else:
                    state = 'abort'
                    break
        else:
            state = 'finished'
        if state == 'finished':
            return True
        return False

    @staticmethod
    def test_skiplines():
        lines = [
                (":label   12 ;  34", False),
                ("", True),
                ("   ", True),
                ("   ; test ", True),
                ("; test ", True),
                ("\t\t; test ", True),
                ]
        error = False
        for line, expected_ret in lines:
            ret = Scanner.scan_for_skipline(line)
            if ret == expected_ret:
                print(f'{line+"|":20s} : {ret} : OK')
            else:
                error = True
                print(f'{line+"|":20s} : {ret} : NOT OK,  NOT {expected_ret}')
        return error

    @staticmethod
    def scan_for_const(line):
        """ -> ok:bool, identifier: str, literal: int """
        identifier = None
        literal = None
        if line.startswith('const'):
            cols = line.split()
            if len(cols) < 4:
               return False, None, None
            if cols[0] != 'const':
               return False, None, None
            ok, identifier, _, _, _ = Scanner.scan_identifier(cols[1], 0)
            if not ok:
               return False
            if cols[2] != '=':
               return False, None, None
            ok, literal, _, _ = Scanner.scan_literal_value(cols[3], 0)
            if not ok:
                return False, None, None
            # check if rest of line is empty
            remainder = ' '.join(cols[4:])
            ok = Scanner.scan_for_skipline(remainder)
            if not ok:
                return False, None, None
            return True, identifier, literal
        return False, None, None


    @staticmethod
    def scan_for_db(line, pos=0):
        """-> ok:bool, bytes: list[int]"""
        state = 'seen_nothing'
        buffer = []
        posafter = None

        for i, c in enumerate(line):
            c = c.lower()
            if state == 'seen_nothing':
                if c in Scanner.whitespace:
                    continue
                elif c == 'd':
                    state = 'seen_d'
                else:
                    state = 'abort'
                    break
            elif state == 'seen_d':
                if c == 'b':
                    state = 'seen_db'
                else:
                    state = 'abort'
                    break
            elif state == 'seen_db':
                if c in Scanner.whitespace:
                    state = 'seen_db_white'
                else:
                    state = 'abort'
                    break
            elif state == 'seen_db_white':
                ok, value, posafter, _ = Scanner.scan_literal_value(line, pos + i)
                if not ok:
                    state = 'abort'
                    break
                buffer.append(value & 0xff)
                state = 'parsing'
            elif state == 'parsing':
                ok, value, posafter, _ = Scanner.scan_literal_value(line, posafter + 1)
                if not ok:
                    state = 'finished'
                    break
                buffer.append(value & 0xff)

        if state == 'finished':
            return True, buffer
        return False, None

    @staticmethod
    def test_db():
        lines = [
                ("db 00 01 02 03", True, [0,1,2,3]),
                ("db 00 01 02 03;", True, [0,1,2,3]),
                ("db 00 ", True, [0]),
                ("db00, 01, 02, 03", False, None),
                ("db 00, 01, 02, 03", False, None),
                ("db", False, None),
                ]
        error = False
        for line, expected_ret, expected_value in lines:
            ret, val = Scanner.scan_for_db(line)
            if ret == expected_ret and val == expected_value:
                print(f'{line+"|":20s} : {ret}, {val} : OK')
            else:
                error = True
                print(f'{line+"|":20s} : {ret}, {val} : NOT OK,  NOT {expected_ret}, {expected_value}')
        return error



    @staticmethod 
    def test_const():
        lines = [
                ("const a = 10", True, 'a', 10),
                ("const ", False, None, None),
                ("", False, None, None),
                ("const a", False, None, None),
                ("const a=10", False, None, None),
                ("const a = ", False, None, None),
                ("const a = hello", False, None, None),
                ("const a = $10", True, 'a', 16),
                ]
        error = False
        for line, expected_ret, expected_value, expected_pos in lines:
            ret, identifier, val = Scanner.scan_for_const(line)
            if ret == expected_ret and identifier == expected_value and val == expected_pos:
                print(f'{line+"|":20s} : {ret}, {val} : OK')
            else:
                error = True
                print(f'{line+"|":20s} : {ret}, {val} : NOT OK,  NOT {expected_ret}, {expected_value}')
        return error



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
        ret = ret or Scanner.test_st()
        ret = ret or Scanner.test_in()
        ret = ret or Scanner.test_out()
        ret = ret or Scanner.test_skiplines()
        ret = ret or Scanner.test_const()
        ret = ret or Scanner.test_db()
        if ret:
            print('THERE WERE ERRORS')
        else:
            print('NO ERRORS')


class SymbolTable:
    def __init__(self):
        self.symbols = {}

    def get(self, key):
        if isinstance(key, str):
            return self.symbols.get(key, 0)
        else:
            return key

    def put(self, key, value):
        self.symbols[key] = value



class Asm:
    def __init__(self, infn, outfn):
        self.infn = infn
        self.outfn = outfn
        self.symboltable = SymbolTable()
        self.mem = {}
        self.pc = 0
        self.max_pc = 0
        self.lines = []
        self.has_errors = False
        self.requested_symbols = set()
        self.macros = {}
        self.addrmode2bin = {
                'absolute': 0x00,
                'immediate': 0x02,
                'extern': 0x04,
                }
        self.register2bin = {
                'pc': 0,
                'a': 1 << 3,
                'b': 2 << 3,
                'c': 3 << 3,
                'd': 4 << 3,
                'e': 5 << 3,
                'f': 6 << 3,
                'g': 7 << 3,
                }
        self.condition2bin = {
                'un': 0,
                'eq': 1 << 6,
                'gt': 2 << 6,
                'sm': 3 << 6,
                }


    def get_symbol_addr(self, addr, modifier):
        if isinstance(addr, str):
            self.requested_symbols.add(addr)
        value = self.symboltable.get(addr)
        if modifier == '<':
            value = value & 0xff
        elif modifier == '>':
            value = int(value / 256)
        return value
        
    def emit(self, load=None, addrmode=None, register=None, condition=None, addr=0, modifier=None):
        value = self.get_symbol_addr(addr, modifier)
        inr2 = value & 0xff
        inr3 = int(value / 256)

        inr1 = 0
        if not load:
            inr1 |= 1

        inr1 |= self.addrmode2bin[addrmode]
        inr1 |= self.register2bin[register]
        inr1 |= self.condition2bin[condition]

        self.mem[self.pc] = inr1
        self.mem[self.pc + 1] = inr2
        self.mem[self.pc + 2] = inr3
        self.pc += 3
        self.max_pc = max(self.pc, self.max_pc)


    def run_pass(self, pass_no=1):
        self.pc = 0
        for i, line in enumerate(self.lines):
            if Scanner.scan_for_skipline(line):
                continue

            # ORG
            ok, value = Scanner.scan_for_org(line, 0)
            if ok:
                self.pc = value
                continue

            # label
            ok, label = Scanner.scan_for_label(line, 0)
            if ok:
                self.symboltable.put(label, self.pc)
                continue

            # const
            ok, identifier, literal = Scanner.scan_for_const(line)
            if ok:
                self.symboltable.put(identifier, literal)
                continue

            # const
            ok, buffer = Scanner.scan_for_db(line)
            if ok:
                for b in buffer:
                    self.mem[self.pc] = b
                    self.pc += 1
                continue

            # JMP
            ok, addr, modifier, condition = Scanner.scan_for_jmp(line, 0)
            if ok:
                self.emit(load=True, addrmode='immediate', register='pc', condition=condition, addr=addr, modifier=modifier)
                continue

            # LD
            ok, register, addrmode, addr, modifier, condition = Scanner.scan_for_ld(line, 0)
            if ok:
                if addrmode == 'immediate':
                    value = self.get_symbol_addr(addr, modifier)
                    if value > 0xff and pass_no == 2:
                        print(f'line {i}: WARNING: literal {addr}={value} > 0xff!')
                        print(f'line {i}> {line}')
                self.emit(load=True, addrmode=addrmode, register=register, condition=condition, addr=addr, modifier=modifier)
                continue

            # ST
            ok, register, addrmode, addr, modifier, condition = Scanner.scan_for_st(line, 0)
            if ok:
                self.emit(load=False, addrmode=addrmode, register=register, condition=condition, addr=addr, modifier=modifier)
                continue


            # IN
            ok, register, addrmode, addr, modifier, condition = Scanner.scan_for_in(line, 0)
            if ok:
                self.emit(load=True, addrmode='extern', register=register, condition=condition, addr=addr, modifier=modifier)
                continue

            # OUT
            ok, register, addrmode, addr, modifier, condition = Scanner.scan_for_out(line, 0)
            if ok:
                self.emit(load=False, addrmode='extern', register=register, condition=condition, addr=addr, modifier=modifier)
                continue

            if pass_no == 1:
                print(f'line {i}: cannot parse:\nline {i}> {line}')
            self.has_errors = True
        return self.has_errors


    def get_unresolved_symbols(self):
        return self.requested_symbols - self.symboltable.symbols.keys()


    def run_include_pass(self):
        with open(self.infn, 'rt') as f:
            lines = [l.strip() for l in f.readlines()]

        self.lines = []
        for i, line in enumerate(lines):
            if line.startswith('include'):
                cols = line.split()
                if len(cols) < 2:
                    print(f'line {i}: missing include file name:\nline {i}> {line}')
                    return
                incfn = cols[1]
                if not os.path.exists(incfn):
                    print(f'line {i}: include file {incfn} not found:\nline {i}> {line}')
                    return

                with open(incfn, 'rt') as incf:
                    ls = [l.strip() for l in incf.readlines()]
                    self.lines.extend(ls)
            else:
                self.lines.append(line)
        return


    def run_macro_read_pass(self):
        state = 'seen_nothing'
        macroname = None

        newlines = []

        for line in self.lines:
            if state == 'seen_nothing':
                if line.lower().startswith('macrodef'):
                    state = 'in_macro'
                    cols = line.split()
                    macroname = cols[1]
                    self.macros[macroname] = []
                else:
                    newlines.append(line)
            elif state == 'in_macro':
                if line.lower().startswith('endmacro'):
                    state = 'seen_nothing'
                else:
                    self.macros[macroname].append(line)

        self.lines = newlines

        if self.macros:
            if False:
                print('Macros:')
                for k, v in self.macros.items():
                    print(f' {k}')
    #                for l in v:
    #                    print(f'  {l}')

    def run_macro_subst_pass(self):
        newlines = []
        instance_count = 0
        for index, line in enumerate(self.lines):
            if line.lower().startswith('macro'):
                cols = line.split()
                macroname = cols[1]
                paramcols = cols[2:]
                params = {}
                for i, c in enumerate(paramcols):
                    params[i+1] = c


                if macroname not in self.macros:
                    print(f'line {index}: macro {macroname} not found!')
                    print(f'line {index}> {line}')
                else:
                    for mline in self.macros[macroname]:
                        cols = mline.split()
                        newcols = []
                        for col in cols:
                            if col.startswith(':@'):
                                col = ':' + col[2:] + f'_{instance_count}'
                            elif col.startswith('@'):
                                # check if param or label
                                if col[1] in Scanner.digits:
                                    # param
                                    paramcount = int(col[1:])
                                    paramval = params.get(paramcount, 0)
                                    col = paramval
                                else:
                                    #label
                                    col = col[1:] + f'_{instance_count}'
                            newcols.append(col)
                        newline = ' '.join(newcols)
                        newlines.append(newline)
            else:
                newlines.append(line)
        self.lines = newlines
        lstfn = os.path.splitext(self.outfn)[0] + '.lst'
        with open(lstfn, 'wt') as f:
            for l in newlines:
                f.write(f'{l}\n')

                
    def assemble(self):
        self.run_include_pass()
        self.run_macro_read_pass()
        self.run_macro_subst_pass()
        has_errors = self.run_pass()
        if not has_errors:
            self.run_pass(2)
        u = self.get_unresolved_symbols()
        if u:
            print('The following symbols are undefined:')
            for x in u:
                print('    ', x)
        print()
        print('Symbol Table:')
        for k, v in self.symboltable.symbols.items():
            print(f'{k:20} : {v}')
        print(f'Generating: {self.outfn}')
        with open(self.outfn, 'wt') as f:
            f.write('MEMORY_INITIALIZATION_RADIX=16;\nMEMORY_INITIALIZATION_VECTOR=\n')
            for pc in range(0, self.max_pc):
                b = self.mem.get(pc, 0xff)
                f.write(f'{b:02x}\n')
        print('Done!')




if __name__ == '__main__':

    infn = sys.argv[1]
    if infn == '--test':
        Scanner.test()
        sys.exit()
    base, _ = os.path.splitext(infn)
    outfn = base + '.coe'
    a = Asm(infn, outfn)
    a.assemble()

