classdef TestTopsEnsemble < dotsTestCase
    % ensemble tests should access objects through ensemble methods
    % whenever possible.  Otherwise it's unfair to expect consistency.
    
    methods
        function self = TestTopsEnsemble(name)
            self = self@dotsTestCase(name);
        end
        
        function testAddContainsRemoveObject(self)
            nObjects = 5;
            ensemble = topsEnsemble('test');
            
            % add several objects, specify ordering
            objects = cell(1, nObjects);
            for ii = 1:nObjects
                objects{ii} = topsFoundation(num2str(ii));
                index = ensemble.addObject(objects{ii}, ii);
                
                assertEqual(ii, index, 'should add with given index')
            end
            
            % verify addition
            for ii = 1:nObjects
                [isContained, index] = ...
                    ensemble.containsObject(objects{ii});
                
                assertTrue(isContained, 'should contain object')
                assertEqual(ii, index, 'should contain at given index')
            end
            
            % remove all at once
            removed = ensemble.removeObject(1:nObjects);
            assertEqual(objects, removed, ...
                'should return all removed objects')
            
            % verify removal
            for ii = 1:nObjects
                [isContained, index] = ...
                    ensemble.containsObject(objects{ii});
                
                assertFalse(isContained, 'should contain object')
            end
        end
        
        function testSetGetObjectProperty(self)
            % ensemble of two objects
            a = topsFoundation('dumb name');
            b = topsFoundation('dumb name');
            ensemble = topsEnsemble('test');
            aIndex = ensemble.addObject(a);
            bIndex = ensemble.addObject(b);
            
            % set and get indexed object names
            ensemble.setObjectProperty('name', 'a', aIndex);
            ensemble.setObjectProperty('name', 'b', bIndex);
            aName = ensemble.getObjectProperty('name', aIndex);
            assertEqual('a', aName, 'should name "a" object by index')
            bName = ensemble.getObjectProperty('name', bIndex);
            assertEqual('b', bName, 'should name "b" object by index')
            
            % get all object names
            names = ensemble.getObjectProperty('name');
            isA = strcmp(names, a.name);
            assertEqual(1, sum(isA), 'should find one "a" object');
            isB = strcmp(names, b.name);
            assertEqual(1, sum(isB), 'should find one "b" object');
            
            % set and get all object names
            ensemble.setObjectProperty('name', 'dumb name');
            names = ensemble.getObjectProperty('name');
            assertTrue(all(strcmp('dumb name', names)), ...
                'should set all names')
        end
        
        function testCallObjectMethod(self)
            % ensemble of two objects
            a = topsFoundation('dumb name');
            b = topsFoundation('dumb name');
            ensemble = topsEnsemble('test');
            aIndex = ensemble.addObject(a);
            bIndex = ensemble.addObject(b);
            
            % ask each object if Matlab considers it "valid"
            isValid = ensemble.callObjectMethod(@isvalid);
            assertTrue(isValid{aIndex}, '"a" object should report valid');
            assertTrue(isValid{bIndex}, '"b" object should report valid');
            
            % ask again but ignore the answers
            ensemble.callObjectMethod(@isvalid);
            
            % ask just one object and get a scalar result
            aIsValid = ensemble.callObjectMethod(@isvalid, [], aIndex);
            assertFalse(iscell(aIsValid), ...
                'single object should return scalar result, not cell');
            assertTrue(aIsValid, '"a" single object should report valid');
        end
        
        function testAutomateObjectMethod(self)
            % ensemble of two objects
            a = topsFoundation('dumb name');
            b = topsFoundation('dumb name');
            ensemble = topsEnsemble('test');
            aIndex = ensemble.addObject(a);
            bIndex = ensemble.addObject(b);
            
            % use static setName() as a phoney object method
            ensemble.automateObjectMethod( ...
                'autoName', @TestTopsEnsemble.setName, {'great name'});
            ensemble.callByName('autoName');
            ensemble.run();
            names = ensemble.getObjectProperty('name');
            assertTrue(all(strcmp('great name', names)), ...
                'should set all names via method call')
        end
        
        function testAssignObject(self)
            % ensemble of two objects
            outer = topsFoundation();
            inner = topsFoundation('inner');
            ensemble = topsEnsemble('test');
            outerIndex = ensemble.addObject(outer);
            innerIndex = ensemble.addObject(inner);
            
            % test assignment by abusing the name property
            %   assign inner to outer.name, plus some deviousPath
            %   dig out deviousPath.name, which should equal inner.name
            %   use the static getDeepValue() instead of direct access
            %   in order to exercise ensemble accessor methods
            
            % test cell element assignment
            subsPath = {'.', 'name', '{}', {7}, '.', 'name'};
            ensemble.assignObject(innerIndex, outerIndex, subsPath{1:4});
            innerName = ensemble.callObjectMethod( ...
                @TestTopsEnsemble.getDeepValue, {subsPath}, outerIndex);
            assertEqual(inner.name, innerName, ...
                'should dig out name of assigned object in a cell')
            
            % clear the assignment
            ensemble.assignObject([], outerIndex, subsPath{1:2});
            
            % test struct assignment
            subsPath = {'.', 'name', '.', 'testField', '.', 'name'};
            ensemble.assignObject(innerIndex, outerIndex, subsPath{1:4});
            innerName = ensemble.callObjectMethod( ...
                @TestTopsEnsemble.getDeepValue, {subsPath}, outerIndex);
            assertEqual(inner.name, innerName, ...
                'should dig out name of assigned object in a cell')
        end
    end
    
    methods (Static)
        % set the name of the given object, like a method
        function setName(object, name)
            object.name = name;
        end
        
        % drill down into an object property, like a method
        function value = getDeepValue(object, subsInfo)
            subs = substruct(subsInfo{:});
            value = subsref(object, subs);
        end
    end
end