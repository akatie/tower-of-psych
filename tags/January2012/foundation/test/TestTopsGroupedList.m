classdef TestTopsGroupedList < TestCase
    
    properties
        groupedList;
        items;
        stringGroups;
        numberGroups;
        stringMnemonics;
        numberMnemonics;
        eventCount;
    end
    
    methods
        function self = TestTopsGroupedList(name)
            self = self@TestCase(name);
        end
        
        function setUp(self)
            self.groupedList = topsGroupedList;
            self.items = {@disp, 'some item', 55.3, containers.Map};
            self.stringGroups = {'a', 'b', 'c d e'};
            self.numberGroups = {-3.45, 1, 2};
            self.stringMnemonics = {'function handle', 'string', 'number', 'object'};
            self.numberMnemonics = {0, 2, -4, 66.567};
            self.eventCount = 0;
        end
        
        function tearDown(self)
            delete(self.groupedList);
            self.groupedList = [];
        end
        
        function addItemsToGroupWithMnemonics(self, items, group, mnemonics)
            for ii = 1:length(items)
                self.groupedList.addItemToGroupWithMnemonic(items{ii}, group, mnemonics{ii});
            end
        end
        
        function hearEvent(self, obj, event)
            self.eventCount = self.eventCount + 1;
        end
        
        function testSingleton(self)
            newList = topsGroupedList;
            assertFalse(self.groupedList==newList, 'topsGroupedList should not be a singleton');
        end
        
        function testSubsSyntax(self)
            g = 'long string group';
            mnemonics = self.stringMnemonics;
            for ii = 1:length(mnemonics)
                self.groupedList{g}{mnemonics{ii}} = self.items{ii};
            end
            
            for ii = 1:length(mnemonics)
                assertTrue(self.groupedList.containsMnemonicInGroup( ...
                    mnemonics{ii}, g), ...
                    'should have added item');
            end
            
            for ii = 1:length(mnemonics)
                item = self.groupedList{g}{mnemonics{ii}};
                assertEqual(item, self.items{ii}, ...
                    'should get same item that was added');
            end
            
            allItemsSubs = self.groupedList{g};
            allItemsNormal = self.groupedList.getAllItemsFromGroup(g);
            assertEqual(allItemsSubs, allItemsNormal, ...
                'should get same group items for subs or normal syntax');
        end
        
        function testAddIdea(self)
            ideas = sort(self.stringMnemonics);
            for ii = 1:length(ideas)
                returnedIdeas{ii} = self.groupedList.addIdea(ideas{ii});
            end
            [groupItems, groupMnemonics] = ...
                self.groupedList.getAllItemsFromGroup(self.groupedList.ideasGroup);
            assertEqual(ideas, returnedIdeas, 'should return passed in idea')
            assertEqual(ideas, groupItems, 'ideas group should contain all ideas')
            assertEqual(ideas, groupMnemonics, 'ideas group should use ideas as mnemonics')
        end
        
        function testAddStringGroupsStringMnemonics(self)
            % add same items to each group
            groups = self.stringGroups;
            mnemonics = self.stringMnemonics;
            for g = groups
                self.addItemsToGroupWithMnemonics(self.items, g{1}, mnemonics);
            end
            n = length(groups) * length(mnemonics);
            assertEqual(n, self.groupedList.length, 'wrong number of items added');
            assertEqual(groups, self.groupedList.groups, 'wrong group identifiers');
        end
        
        function testAddNumberGroupsNumberMnemonics(self)
            % add same items to each group
            groups = self.numberGroups;
            mnemonics = self.numberMnemonics;
            for g = groups
                self.addItemsToGroupWithMnemonics(self.items, g{1}, mnemonics);
            end
            n = length(groups) * length(mnemonics);
            assertEqual(n, self.groupedList.length, 'wrong number of items added');
            assertEqual(groups, self.groupedList.groups, 'wrong group identifiers');
        end
        
        function testAddStringGroupsHeterogeneousMnemonics(self)
            % add string mnemonics to one group
            g = self.stringGroups{1};
            self.addItemsToGroupWithMnemonics(self.items, g, self.stringMnemonics);
            
            % add number mnemonics to another group
            g = self.stringGroups{2};
            self.addItemsToGroupWithMnemonics(self.items, g, self.numberMnemonics);
            
            n = length(self.stringMnemonics) + length(self.numberMnemonics);
            assertEqual(n, self.groupedList.length, 'wrong number of items added');
        end
        
        function testRedundantAddDoesNoting(self)
            g = self.stringGroups{1};
            self.addItemsToGroupWithMnemonics(self.items, g, self.stringMnemonics);
            n = length(self.stringMnemonics);
            assertEqual(n, self.groupedList.length, 'wrong number of items added');
            
            self.addItemsToGroupWithMnemonics(self.items, g, self.stringMnemonics);
            assertEqual(n, self.groupedList.length, 'redundant add should have done nothing');
        end
        
        function testRemoveItem(self)
            g = self.stringGroups{1};
            self.addItemsToGroupWithMnemonics(self.items, g, self.stringMnemonics);
            n = length(self.stringMnemonics);
            assertEqual(n, self.groupedList.length, 'wrong number of items added');
            
            self.groupedList.removeItemFromGroup(self.items{1}, g);
            assertEqual(n-1, self.groupedList.length, 'should have removed 1 item');
        end
        
        function testRemoveMnemonic(self)
            g = self.stringGroups{1};
            self.addItemsToGroupWithMnemonics(self.items, g, self.stringMnemonics);
            n = length(self.stringMnemonics);
            assertEqual(n, self.groupedList.length, 'wrong number of items added');
            
            self.groupedList.removeMnemonicFromGroup(self.stringMnemonics{1}, g);
            assertEqual(n-1, self.groupedList.length, 'should have removed 1 item');
        end
        
        function testRemoveGroup(self)
            g = self.stringGroups{1};
            self.addItemsToGroupWithMnemonics(self.items, g, self.stringMnemonics);
            
            g = self.stringGroups{2};
            self.addItemsToGroupWithMnemonics(self.items, g, self.stringMnemonics);
            
            n = 2*length(self.stringMnemonics);
            assertEqual(n, self.groupedList.length, 'wrong number of items added');
            
            self.groupedList.removeGroup(self.stringGroups{1});
            n = length(self.stringMnemonics);
            assertEqual(n, self.groupedList.length, 'should have removed half the items');
            
            self.groupedList.removeGroup(self.stringGroups{2});
            assertEqual(0, self.groupedList.length, 'should have removed all items');
            
            assertTrue(isempty(self.groupedList.groups), 'should have removed all groups')
        end
        
        function testRemoveAllGroups(self)
            groups = self.stringGroups;
            mnemonics = self.stringMnemonics;
            for g = groups
                self.addItemsToGroupWithMnemonics(self.items, g{1}, mnemonics);
            end
            assertTrue(self.groupedList.length > 0, 'list should be full')
            
            self.groupedList.removeAllGroups;
            assertTrue(self.groupedList.length == 0, 'list should be empty')
        end
        
        function testMergeGroups(self)
            % add same items to each group
            for g = self.numberGroups
                self.addItemsToGroupWithMnemonics(self.items, g{1}, self.numberMnemonics);
            end
            n = length(self.numberGroups) * length(self.numberMnemonics);
            assertEqual(n, self.groupedList.length, 'wrong number of items added');
            
            bigGroup = 100;
            self.groupedList.mergeGroupsIntoGroup(self.numberGroups, bigGroup);
            groups = self.groupedList.groups;
            assertEqual(sum([groups{:}]==bigGroup), 1, 'should have new, big group')
            n = n + length(self.numberMnemonics);
            assertEqual(n, self.groupedList.length, 'merge should have added items');
        end
        
        function testCantMergeHeterogeneousGroups(self)
            g = self.stringGroups{1};
            self.addItemsToGroupWithMnemonics(self.items, g, self.stringMnemonics);
            
            g = self.stringGroups{2};
            self.addItemsToGroupWithMnemonics(self.items, g, self.numberMnemonics);
            
            bigGroup = 'strings and numbers';
            f = @()self.groupedList.mergeGroupsIntoGroup(self.stringGroups(1:2), bigGroup);
            assertExceptionThrown(f, 'MATLAB:Containers:TypeMismatch');
        end
        
        function testContainsItems(self)
            g = self.stringGroups{1};
            self.addItemsToGroupWithMnemonics( ...
                self.items, g, self.stringMnemonics);
            
            assertTrue(self.groupedList.containsGroup(g), ...
                'grouped list should contain group for newly added item');
            
            noG = self.stringGroups{2};
            assertFalse(self.groupedList.containsGroup(noG), ...
                'grouped list should not think it has bogus group');
            
            noM = 'bogus mnemonic';
            for m = self.stringMnemonics
                assertTrue(self.groupedList.containsMnemonicInGroup(m{1}, g), ...
                    'group should contain mnemonic for newly added item');
                
                assertFalse(self.groupedList.containsMnemonicInGroup(noM, g), ...
                    'group should not contain bogus mnemonic');
                
                assertFalse(self.groupedList.containsMnemonicInGroup(m{1}, noG), ...
                    'group should not contain mnemonic in bogus group');
            end
            
            noItem = 'bogus item';
            for item = self.items
                assertTrue(self.groupedList.containsItemInGroup(item{1}, g), ...
                    'group should contain newly added item');
                
                assertFalse(self.groupedList.containsItemInGroup(noItem, g), ...
                    'group should contain bogus item');
                
                assertFalse(self.groupedList.containsItemInGroup(item{1}, noG), ...
                    'group should not contain item in bogus group');
            end
        end
        
        function getItem(self)
            g = self.numberGroups{1};
            self.addItemsToGroupWithMnemonics(self.items, g, self.numberMnemonics);
            
            for ii = 1:length(self.items)
                item = self.groupedList.getItemFromGroupWithMnemonic(...
                    g, self.numberMnemonics{ii});
                assertEqual(self.items{ii}, item, 'should get same item that was added');
            end
            
            noM = 'bogus mnemonic';
            item = self.groupedList.getItemFromGroupWithMnemonic(g, noM);
            assertEqual(isempty(item), 'should not get item for bogus mnemonic');
        end
        
        function testGetAllItems(self)
            g = self.stringGroups{1};
            self.addItemsToGroupWithMnemonics(self.items, g, self.stringMnemonics);
            
            items = self.groupedList.getAllItemsFromGroup(g);
            assertEqual(size(self.items), size(items), 'should get same number of items added to group')
            
            [items, mnemonics] = self.groupedList.getAllItemsFromGroup(g);
            assertEqual(size(self.items), size(items), 'should get same number of items added to group')
            assertEqual(size(self.stringMnemonics), size(mnemonics), 'should get same number of mnemonics added to group')
            
            for ii = 1:length(self.stringMnemonics)
                % look up returned items by mnemonics
                jj = strcmp(mnemonics, self.stringMnemonics{ii});
                assertEqual(sum(jj), 1, 'added and returned mnemonics should be 1:1')
                assertEqual(self.items{ii}, items{jj}, 'added and returned items should be 1:1')
            end
        end
        
        function testGetAllItemsAsStruct(self)
            groupStruct = self.groupedList.getAllItemsFromGroupAsStruct('');
            assertEqual(length(groupStruct), 0, 'struct should have no length');
            
            % should make struct array for all items in group
            g = self.stringGroups{1};
            self.addItemsToGroupWithMnemonics(self.items, g, self.stringMnemonics);
            groupStruct = self.groupedList.getAllItemsFromGroupAsStruct(g);
            
            assertEqual(length(groupStruct), length(self.items), 'struct is wrong size');
            assertTrue(all(strcmp(g, {groupStruct.group})), 'struct should have same size as group');
            
            items = {groupStruct.item};
            assertEqual(size(self.items), size(items), 'should get same number of items added to group')
            
            mnemonics = {groupStruct.mnemonic};
            assertEqual(size(self.stringMnemonics), size(mnemonics), 'should get same number of mnemonics added to group')
            
            for ii = 1:length(self.stringMnemonics)
                % look up returned items by mnemonics
                jj = strcmp(mnemonics, self.stringMnemonics{ii});
                assertEqual(sum(jj), 1, 'added and returned mnemonics should be 1:1')
                assertEqual(self.items{ii}, items{jj}, 'added and returned items should be 1:1')
            end
        end
        
        function testPropertyChangeEventPosting(self)
            % listen for event postings
            props = properties(self.groupedList);
            n = length(props);
            for ii = 1:n
                listeners(ii) = self.groupedList.addlistener(props{ii}, 'PostSet', @self.hearEvent);
            end
            
            % trigger a posting for each property
            self.eventCount = 0;
            for ii = 1:n
                self.groupedList.(props{ii}) = self.groupedList.(props{ii});
            end
            assertEqual(self.eventCount, n, 'heard wrong number of property set events');
            delete(listeners);
        end
        
        function testNewItemEventPosting(self)
            listeners(1) = self.groupedList.addlistener('NewAddition',  @self.hearEvent);
            
            g = self.stringGroups{1};
            self.addItemsToGroupWithMnemonics(self.items, g, self.stringMnemonics);
            n = length(self.stringMnemonics);
            assertEqual(self.eventCount, n, 'heard wrong number of new addition events');
            delete(listeners);
        end
        
        function testRegularExpressions(self)
            wildcard = '.';
            matches = self.groupedList.getGroupNamesMatchingExpression( ...
                wildcard);
            assertTrue(isempty(matches), ...
                'empty list should match no groups to wildcard expression')
            
            groups = self.stringGroups;
            mnemonics = self.stringMnemonics;
            for g = groups
                self.addItemsToGroupWithMnemonics(self.items, g{1}, mnemonics);
            end
            matches = self.groupedList.getGroupNamesMatchingExpression( ...
                wildcard);
            assertEqual(matches, groups,...
                'list should match all groups to wilcard expression')
            
            numberList = topsGroupedList;
            groups = self.numberGroups;
            for g = groups
                numberList.addItemToGroupWithMnemonic(1,g{1},1);
            end
            matches = numberList.getGroupNamesMatchingExpression( ...
                wildcard);
            assertTrue(isempty(matches), ...
                'list should not match numeric groups to wildcard expression')
        end
    end
end