STATE_NONE = 0
STATE_INTEGER = 1
STATE_ARITHMETIC = 2

TYPE_INTEGER = 0
TYPE_ARITHMETIC = 1



numerals = '0123456789ABCDEF'
arithmetics = '+-*/'

def _build_data_tree(expr: str):
    state = STATE_NONE

    data = []
    current_dat = -1

    # Build data tree
    for i, c in enumerate(expr.upper()):
        if c in numerals:
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
        elif c in arithmetics:
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
    
    return lvalue


def evaluate(expr: str):
    data = _build_data_tree(expr)
    return _evaluate(data)


if __name__ == '__main__':
    expr = '5 + 2 * 10' # Problem
    result = evaluate(expr)
    print(result)