#!/usr/bin/env python3

"""
    tm - task manager

    author: Ronald Kaiser
    date: Oct 18, 2026
    updated: Oct 22, 2026

    This is a script that processes the tm.pro file within the same directory.

    The idea is to write down your tasks in the tm.pro and run some analysis
    with this script.

    The tm.pro file lists all your tasks with the following structure:

        tm.pro content:
            [task1]: [short task name]
            [task description in a multiline string.
             This is the second line of the description]
            [:key1:value1]
            [:key2:value2]

            [task2]: [short task name]
            [task description in a multiline string.]
            [:key1:value1]
            [:key2:value2]
            [:depends_on:task1]
            ...
    
    Some of the features that already work (see tm.pro for examples):
    1. Add Key value pairs to each task
        * add them after the task description
    2. Order of execution plan suggestion:
        * each task can have a list of dependencies
        * based on that, this script suggests a plan of execution
    3. Search:
        * run it like `tm --search word`
"""


import argparse
import os


CYAN       = "\033[36m"
CYAN_BOLD  = "\033[96m"
GRAY       = "\033[90m"
GREEN      = "\033[32m"
GREEN_BOLD = "\033[92m"
ORANGE_BOLD= "\033[1;38;5;208m"
END        = "\033[0m"
LINE_WIDTH = 100


def print_task_name(_id, name, done):
    id_color = GREEN
    name_color = GREEN_BOLD
    sign = "🟢"
    if done:
        id_color = name_color = GRAY
        sign = "☑️"
    print(f"    {sign} {id_color}[{_id}]{END}: {name_color}{name}{END}")


def print_task_description(description):
    for line in description:
        print("    ", line.strip())


def print_task_key_values(task):
    key_color = CYAN_BOLD
    value_color = CYAN
    for key in task.keys():
        print(f"     {key_color}{key}{END}:{value_color}{task[key].strip()}{END}")


def print_tasks_header_footer(func):
    def wrapper(*args, **kwargs):
        print(f"{CYAN}tasks{END}".center(LINE_WIDTH, '.'))
        result = func(*args, **kwargs)
        return result
    return wrapper


def parse_file():
    file_dir = os.path.dirname(os.path.abspath(__file__))
    file_path = file_dir + "/tm.pro"
    f = open(file_path)
    tasks = {}
    cur = ""
    for line in f.readlines():
        if len(line) > 1 and not cur:
            cur, name = line.split(":")
            if cur in tasks:
                raise ValueError(f"task {cur} duplicated")
            tasks[cur] = { "name": name.strip(), "description": [] }
            continue

        if len(line) > 1:
            if line.startswith(":"):
                _, key, value = line.split(":")
                tasks[cur][key] = value
            else:
                tasks[cur]["description"].append(line)
        else:
            cur = ""
    return tasks


def print_stats(tasks):
    print()
    done = sum(1 for task in tasks if "done" in tasks[task])
    total = len(tasks)
    if total == 0:
        return
    n = 50
    full = int(((done) / total) * n)
    empty = n - full
    print(f"    📊 {CYAN_BOLD}Progress: " + GREEN + "█"*full + END + GRAY + "░"*empty + f"{END}{CYAN} {done} / {total} ({round(done/total, 2)*100}%){END}\n")


def highlight(text, word):
    return text.replace(word, f"{ORANGE_BOLD}{word}{END}")


@print_tasks_header_footer
def print_tasks(tasks, ignore_done=True, highlight_word=None):
    print()
    for i, task in enumerate(tasks):
        if not ignore_done and "done" in tasks[task]:
            continue # do not show done tasks 

        if highlight_word:
            word = highlight_word
            _id = highlight(task, word)
            name = highlight(tasks[task]["name"], word)
            description = [highlight(line, word) for line in tasks[task]["description"]]
            key_values = {
                highlight(key, word):highlight(value, word)
                for key, value in tasks[task].items()
                if key not in ["id", "name", "description"]
            }
        else:
            _id = task
            name = tasks[task]["name"]
            description = tasks[task]["description"]
            key_values = {
                key:value
                for key, value in tasks[task].items()
                if key not in ["id", "name", "description"]
            }
        print_task_name(_id, name, done="done" in tasks[task])
        print_task_description(description)
        print_task_key_values(key_values)
        print()

    print_stats(tasks)
    return tasks


def is_task_done(_id, tasks):
    return "done" in tasks[_id]


def build_graph(tasks):
    graph = { task: [] for task in tasks }
    for task, item in tasks.items():
        dependencies = item["depends_on"].strip().split(",") if "depends_on" in item else []
        for dependency in dependencies:
            graph[dependency].append(task)
    return graph


def topological_sort(graph):
    in_degrees = {node:0 for node in graph} 

    to_process = set()
    for node in graph:
        for u in graph[node]:
            in_degrees[u] += 1

    for node in in_degrees:
        if in_degrees[node] == 0:
            to_process.add(node)

    plan = []

    while to_process:
        node = to_process.pop()
        plan.append(node)
        for u in graph[node]:
            in_degrees[u] -= 1
            if in_degrees[u] == 0:
                to_process.add(u)

    if len(plan) < len(in_degrees):
        raise ValueError # cycle detected
    return plan


def build_and_print_plan(tasks):
    graph = build_graph(tasks)
    try:
        plan = topological_sort(graph)
    except ValueError:
        print("\n 🔴 CYCLE DETECTED! Some tasks depend on each other\n")
        return

    print(f"{CYAN}plan{END}".center(LINE_WIDTH, "."))
    i = 0
    for item in plan:
        if not is_task_done(item, tasks):
            i += 1
            print(f"      {i}.", item)

    if i == 0:
        print("All done! Congratz! 🎉 ")
    return plan


def search_tasks_and_print_result(word, tasks):
    to_print = {}
    for task in tasks:
        if word in task:
            to_print[task] = tasks[task]
            continue
        for key, value in tasks[task].items():
            if word in key:
                to_print[task] = tasks[task]
                continue
            if isinstance(value, list):
                for item in value:
                    if word in item:
                        to_print[task] = tasks[task]
                        break
            else:
                if word in value:
                    to_print[task] = tasks[task]

    print_tasks(to_print, ignore_done=True, highlight_word=word)


if __name__ == "__main__":
    print(f"""{CYAN}
   ░██                    
   ░██                    
░████████ ░█████████████  
   ░██    ░██   ░██   ░██ 
   ░██    ░██   ░██   ░██ 
   ░██    ░██   ░██   ░██ 
    ░████ ░██   ░██   ░██ 
  v0.1 - by Ronald Kaiser
{END}""")

    parser = argparse.ArgumentParser()
    parser.add_argument("-a", "--all", action="store_true", help="print all tasks")
    parser.add_argument("-s", "--search", type=str, default="", help="search for word")
    args = vars(parser.parse_args())
    tasks = parse_file()
    word = args["search"]
    if word:
        search_tasks_and_print_result(word, tasks)
    else:
        print_tasks(tasks, ignore_done=args["all"])
        build_and_print_plan(tasks)
