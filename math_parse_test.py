STATE_NONE = 0
STATE_INTEGER = 1
STATE_ARITHMETIC = 2
STATE_SCOPE = 3

TYPE_INTEGER = 0
TYPE_ARITHMETIC = 1
TYPE_SCOPE = 2




numerals = '0123456789'
arithmetics = '+-*/'

def _build_data_tree(expr: str):
    state = STATE_NONE

    data = []
    current_dat = -1
    scopes_to_pass = 0

    current_scope = -1


    # Build data tree
    for i, c in enumerate(expr.upper()):
        if state != STATE_SCOPE and c in numerals:
            if state != STATE_INTEGER:
                current_dat += 1
                data.append(
                    {
                        'type': TYPE_INTEGER,
                        'value': c
                    }
                )
            else:
                data[current_dat]['value'] += c
            state = STATE_INTEGER
        elif state != STATE_SCOPE and c in arithmetics:
            if state == STATE_ARITHMETIC:
                print('ERROR: Bad arithmetic!')
                return None
            
            current_dat += 1
            data.append(
                {
                    'type': TYPE_ARITHMETIC,
                    'value': c
                }
            )
            state = STATE_ARITHMETIC
        
        elif c == '(':
            scopes_to_pass += 1
            if state != STATE_SCOPE:
                current_dat += 1
                current_scope = current_dat
                data.append(
                    {
                        'type': TYPE_SCOPE,
                        'value': i+1 # Scope start
                    }
                )
                state = STATE_SCOPE
        
        elif c == ')':
            scopes_to_pass -= 1
            if scopes_to_pass == 0:
                if current_scope == -1:
                    print('ERROR: Invalid scope!')
                    return None
                scope_start = data[current_scope]['value']
                scope_end = i
                data[current_scope]['value'] = _build_data_tree(expr[scope_start:scope_end])

                state = STATE_NONE

        
    return data

def _handle_operation(lvalue, rvalue, operation):
    match operation:
        case '+':
            return lvalue + rvalue
        case '-':
            return lvalue - rvalue
        case '*':
            return lvalue * rvalue
        case '/':
            return lvalue / rvalue

def _evaluate(data: dict):
    lvalue = 0
    rvalue = 0
    left = True
    operation = '+'
    for entry in data:
        if entry['type'] == TYPE_INTEGER:
            if left:
                lvalue = int(entry['value'])
                left = False
            else:
                rvalue = int(entry['value'])
                lvalue = _handle_operation(lvalue, rvalue, operation)
                left = True
        elif entry['type'] == TYPE_ARITHMETIC:
            operation = entry['value']
            left = False
        elif entry['type'] == TYPE_SCOPE:
            if left:
                lvalue = _evaluate(entry['value'])
                left = False
            else:
                rvalue = _evaluate(entry['value'])
                lvalue = _handle_operation(lvalue, rvalue, operation)
                left = True
    
    return lvalue


def evaluate(expr: str):
    data = _build_data_tree(expr)
    print(data)
    return _evaluate(data)


if __name__ == '__main__':
    expr = '-2 + 5 + (2 * (5+5))'
    result = evaluate(expr)
    print(result)