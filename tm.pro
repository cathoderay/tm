task1: parse file
This is the first task of the task manager. 
It should accept a multiline description.
:done:

task2: list tasks command
It should pretty print the list of tasks
:done:

task3: read additional keys
every line that starts with : will be treated as key-value in the task
:key:value
:depends_on:task1
:done:

task4: write down more tasks
Brainstorm new ideas to add into task-manager.
Note: this task does not add much value. There will
always be more tasks or the project is done.
I'll consider this one done.
:done:

task5: add done key/value
Color the task according to the done key
:done:

task6: write down documentation
maybe it's too early.
:key:value
:depends_on:task10,task7
:done:false

task7: syntax highlight
It would be nice to develop some sort of editor and have syntax highlight.
Not sure if it's worth the time, though.
:done:false

task8: make list option the default
instead of running like: ./tm list, let's make the list option the default
:done:

task9: read tm.pro script dir
It would be nice to read project file from same dir as script
:done:

task10: model tasks as a graph
It would be nice to provide a topological sorting of tasks, so it can suggest
a plan of execution.
:depends_on:task12
:done:

task11: task to test topological sort
This is a dummy task to test the topological sorting algorithm.
:depends_on:task10
:done:

task12: build graph based on depends_on key
Task to finish before task10
:done:

task13: show only todo tasks
Only show tasks without "done" key
:done:

task14: add new tasks
come up with new features
