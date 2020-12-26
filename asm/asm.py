import sys
import os

class Scanner:
    digits = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9']
    hexdigits = digits.copy()
    hexdigits.extend(['a', 'b', 'c', 'd', 'e', 'f'])
    hexleader = '$'
    whitespace = [' ', '\t']
    commentlead = ';'
    modifiers = ['<', '>']
    alpha = [chr(c) for c in range(ord('A'), ord('Z') + 1)]
    alpha = alpha + [c.lower() for c in alpha]
    identifier_start = alpha + ['_']
    identifier_mid = alpha + digits 
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
    def test():
        Scanner.test_scan_literal()





class Asm:
    def __init__(self):
        self.symbols = {}
        self.mem = {}
        self.pc = 0
        self.max_pc = 0

if __name__ == '__main__':
    Scanner.test()

