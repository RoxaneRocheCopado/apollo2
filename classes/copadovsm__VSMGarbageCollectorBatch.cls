/*
This file is generated and isn't the actual source code for this
managed global class.
This read-only file shows the class's global constructors,
methods, variables, and properties.
To enable code to compile, all methods return null.
*/
global class VSMGarbageCollectorBatch implements Database.Batchable<Object>, Database.Stateful {
    global VSMGarbageCollectorBatch(List<copadovsm.VSMGarbageCollectorBatch.GarbageCollectorWrapper> workItemWrapperList) {

    }
    global void execute(Database.BatchableContext bc, List<Object> scope) {

    }
    global void finish(Database.BatchableContext bc) {

    }
    global System.Iterable start(Database.BatchableContext bc) {
        return null;
    }
global class GarbageCollectorWrapper {
    global String id {
        get;
        set;
    }
    global String objName {
        get;
        set;
    }
    global GarbageCollectorWrapper() {

    }
}
}
