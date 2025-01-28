# Make confuses me all day
from os import system

# Consts
STATE_NONE = 0
STATE_TASK = 1

# Globals
global_symbols = {}
tasks = []


def _open_mkt(path='mkt'):
    try:
        with open(path) as f:
            data = f.read().splitlines()
    except FileNotFoundError:
        print(f'ERROR: "{path}" file not found!')
    return data


def _preprocess(data: list):
    new_data = []
    for l in data:
        args = l.split(' ')
        if l:
            if l[0] == '#':
                incl_dat = _open_mkt(args[1] + '/mkt')
                incl_dat = _preprocess(incl_dat)
                for il in incl_dat:
                    new_data.append(il.strip())
            else:
                new_data.append(l.strip())
    return new_data

def _process_global(args):
    if len(args) != 3:
        print('ERROR: Invalid global declaration!')
        return
    
    global_symbols[args[1]] = args[2]



def _assemble(data: list):
    state = STATE_NONE
    task_begin = -1
    task_label = 'NONE'
    for i, l in enumerate(data):
        args = l.split(' ')

        if l[0] == '@':
            if 'global' in l:
                _process_global(args)
            if 'task' in l:
                if len(args) != 2:
                    print('ERROR: Invalid task declaration!')
                state = STATE_TASK
                task_begin = i+1
                task_label = args[1]
            if 'end' in l:
                if state == STATE_TASK:
                    state = STATE_NONE
                    task_end = i
                    tasks.append(
                        {
                            'label':task_label,
                            'data':data[task_begin:task_end]
                        }
                    )

def _insert_globals(l: str) -> str:
    return l.format(**global_symbols)

def _find_task(label: str):
    task = None
    for t in tasks:
        if t['label'] == label:
            task = t
    if task == None:
        print(f'ERROR: Could not find task "{label}"!')

    return task

def _exec(task: dict):
    _tasks = task['data']
    
    for l in _tasks:
        l = _insert_globals(l)
        if l[0] == '!':
            t = _find_task(l[1:])
            if not t: break # Already printed error
            _exec(t)
        else:
            print('MKT: ' + l)
            system(l)

            
        


def make():
    data = _open_mkt()
    data = _preprocess(data)
    _assemble(data)
    # print(tasks)

    # Find make task
    make_task = _find_task('make')
    _exec(make_task)
    

if __name__ == '__main__':
    make()