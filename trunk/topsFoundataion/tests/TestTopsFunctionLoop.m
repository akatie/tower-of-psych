classdef TestTopsFunctionLoop < TestCase
    
    properties
        functionLoop;
        mathMode;
        mathFunctions;
        orderedMode;
        orderedFunctions;
        order;
    end
    
    methods
        function self = TestTopsFunctionLoop(name)
            self = self@TestCase(name);
        end
        
        function setUp(self)
            self.functionLoop = topsFunctionLoop;            

            self.mathMode = 'maths';
            self.mathFunctions  = { ...
                {@eye, 6}, ...
                {@mod, 3, 2}};
            
            self.orderedMode = 'ordered';
            self.orderedFunctions = { ...
                {@self.executeFunction, 1}, ...
                {@self.executeFunction, 2}, ...
                {@self.executeFunction, 3}, ...
                {@self.executeFunction, 4}};
            
            self.order = [];
        end
        
        function tearDown(self)
            delete(self.functionLoop);
            self.functionLoop = [];
        end
        
        function executeFunction(self, value)
            self.order(end+1) = value;
        end
        
        function addFunctionsToModesInOrder(self)
            % bunch of functions for two different modes
            for ii = 1:length(self.mathFunctions)
                self.functionLoop.addFunctionToModeWithPrecedence(self.mathFunctions{ii}, self.mathMode, -ii);
            end
            
            for ii = 1:length(self.orderedFunctions)
                self.functionLoop.addFunctionToModeWithPrecedence(self.orderedFunctions{ii}, self.orderedMode, -ii);
            end
        end
        
        function testSingleton(self)
            newLoop = topsFunctionLoop;
            assertFalse(self.functionLoop==newLoop, 'topsFunctionLoop should not be a singleton');
        end
        
        function testRetrieveFunctionsByModeAndPrecedence(self)
            self.addFunctionsToModesInOrder;
            
            mathLoop = self.functionLoop.getFunctionListForMode(self.mathMode);
            for ii = 1:length(mathLoop)
                assertEqual(mathLoop{ii}, self.mathFunctions{ii}, ...
                    'failed to add and retrieve functions for mode, in order');
            end

            orderedLoop = self.functionLoop.getFunctionListForMode(self.orderedMode);
            for ii = 1:length(orderedLoop)
                assertEqual(orderedLoop{ii}, self.orderedFunctions{ii}, ...
                    'failed to add and retrieve functions for mode, in order');
            end
        end

        function testRunFunctionsByModeAndPrecedence(self)
            self.addFunctionsToModesInOrder;
            % run once through loop
            self.functionLoop.runInModeForDuration(self.orderedMode, 0);
            assertFalse(isempty(self.order), 'failed to execute functions');
            assertTrue(all(diff(self.order))>0, 'executes functions in wrong order');
        end
        
        function testPropertyChangeEventPosting(self)
            global eventCount
            eventCount = 0;
            
            % listen for event postings
            props = properties(self.functionLoop);
            n = length(props);
            for ii = 1:n
                self.functionLoop.addlistener(props{ii}, 'PostSet', @hearEvent);
            end
            
            % trigger a posting for each property
            for ii = 1:n
                self.functionLoop.(props{ii}) = self.functionLoop.(props{ii});
            end
            assertEqual(eventCount, n, 'heard wrong number of property set events');
            clear global eventCount
            function hearEvent(metaProp, event)
                eventCount = eventCount + 1;
            end
        end
    end
end