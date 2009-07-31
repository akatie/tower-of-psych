function testTopsBlockTree

%% should not behave like a singleton
clear
clc
tree1 = topsBlockTree;
tree2 = topsBlockTree;
assert(tree1~=tree2, 'failed to get unique instances')

%% should add and preview functions
clear
clc
tree = topsBlockTree;
topsDataLog.flushAllData;

tree.name = 'test tree';
tree.blockBeginFcn = {@disp, 'block begin'};
tree.blockActionFcn = {@disp, 'block action'};
tree.blockEndFcn = {@disp, 'block end'};

tree.preview;
summary = topsDataLog.getAllDataSorted;
assert(length(summary) == 3, 'wrong number of summary functions');
assert(isequal(tree.blockBeginFcn, summary(1).data), 'wrong block begin function');
assert(isequal(tree.blockActionFcn, summary(2).data), 'wrong block action function');
assert(isequal(tree.blockEndFcn, summary(3).data), 'wrong block end function');

%% should add and preview children
clear
clc
tree = topsBlockTree;
topsDataLog.flushAllData;

tree.name = 'test tree';
for ii = 1:3
    child = topsBlockTree;
    child.name = 'child tree';
    tree.addChild(child);
end
tree.preview;
summary = topsDataLog.getAllDataSorted;
assert(length(summary) == 3*(ii+1), 'wrong number of child blocks logged');

%% should run functions and children in depth-first order
clear
clc
tree = topsBlockTree;
child = topsBlockTree;
grandchild = topsBlockTree;

topsDataLog.flushAllData;

tree.name = 'test tree';
child.name = 'child';
grandchild.name = 'grandchild';
tree.addChild(child);
child.addChild(grandchild);

% ordered functions
for ii = 9:-1:1
    fcn{ii} = {@disp, ii};
end
tree.blockBeginFcn = fcn{1};
tree.blockActionFcn = fcn{2};
child.blockBeginFcn = fcn{3};
child.blockActionFcn = fcn{4};
grandchild.blockBeginFcn = fcn{5};
grandchild.blockActionFcn = fcn{6};
grandchild.blockEndFcn = fcn{7};
child.blockEndFcn = fcn{8};
tree.blockEndFcn = fcn{9};

tree.run;
summary = topsDataLog.getAllDataSorted;
for ii = 1:9
    assert(isequal(fcn{ii}, summary(ii).data), 'function summary in wrong order');
end


%% should post event when props change
clear
clc
global eventCount
eventCount = 0;
tree = topsBlockTree;
props = properties(tree);
n = length(props);
for ii = 1:n
    tree.addlistener(props{ii}, 'PostSet', @hearEvent);
end
for ii = 1:n
    tree.(props{ii}) = tree.(props{ii});
end
assert(eventCount==length(props), 'heard wrong number of set events')
clear global eventCount

function hearEvent(metaProp, event)
global eventCount
eventCount = eventCount + 1;