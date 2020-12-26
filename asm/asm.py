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
    register = [chr(c) for c in range(ord('A'), ord('G') + 1)]
    register = register + [c.lower() for c in register]

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

        if state == 'finished' and len(collected):
            return True, collected, modifier, pos + index, state
        return False, None, None, pos + index, state


    @staticmethod
    def test_scan_literal():
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

    @staticmethod
    def test_scan_identifier():
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
                print(f'{line+"|":20s} : {ret}, {val}, {mod} : NOT OK ({state}) NOT {expected_ret}, {expected_value}, {expected_mod}')
                
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
                print(state, f'>|{c}|')
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
                ]
        for line, expected_ret, expected_value in lines:
            ret, val = Scanner.scan_for_label(line, 0)
            if ret == expected_ret and val == expected_value:
                print(f'{line+"|":20s} : {ret}, {val} : OK')
            else:
                print(f'{line+"|":20s} : {ret}, {val} : NOT OK,  NOT {expected_ret}, {expected_value}')

    @staticmethod
    def test():
        Scanner.test_scan_literal()
        Scanner.test_scan_identifier()
        Scanner.test_org()
        Scanner.test_label()





class Asm:
    def __init__(self):
        self.symbols = {}
        self.mem = {}
        self.pc = 0
        self.max_pc = 0

if __name__ == '__main__':
    Scanner.test()

