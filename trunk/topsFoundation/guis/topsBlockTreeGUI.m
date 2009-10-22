classdef topsBlockTreeGUI < topsGUI
    properties
        topLevelBlockTree;
        currentBlockTree;
    end
    
    properties(Hidden)
        blocksGrid;
        blockDetailPanel;
        blockTreeCount;
        nameText;
        iterationsText;
        blockBeginFcnText;
        blockActionFcnText;
        blockEndFcnText;
        userDataText;
        runButton;
    end
    
    methods
        function self = topsBlockTreeGUI(topLevelTree)
            self = self@topsGUI;
            self.title = 'Block Tree Viewer';
            self.createWidgets;
            
            if nargin
                self.topLevelBlockTree = topLevelTree;
                self.repopulateBlocksGrid;
                self.displayDetailsForBlock(topLevelTree);
            end
        end
        
        function createWidgets(self)
            left = 0;
            right = 1;
            bottom = 0;
            top = 1;
            xDiv = (1/3);
            
            % custom widget class, in tops/utilities
            self.blocksGrid = ScrollingControlGrid( ...
                self.figure, [left, bottom, xDiv-left, top-bottom]);
            
            pad = .03;
            self.blockDetailPanel = uipanel( ...
                'Parent', self.figure, ...
                'BorderType', 'line', ...
                'BorderWidth', 1, ...
                'Title', '', ...
                'BackgroundColor', 'none', ...
                'Units', 'normalized', ...
                'Position', [xDiv+pad bottom+pad, right-xDiv-2*pad, top-bottom-2*pad], ...
                'Clipping', 'on', ...
                'HandleVisibility', 'off', ...
                'HitTest', 'off', ...
                'SelectionHighlight', 'off', ...
                'Visible', 'on');
            
            height = .05;
            width = .92;
            inset = 1-width;
            y = 1;
            self.nameText = uicontrol( ...
                'Parent', self.blockDetailPanel, ...
                'BackgroundColor', self.lightColor, ...
                'Style', 'text', ...
                'Units', 'normalized', ...
                'String', 'block name', ...
                'Position', [0, 1-(y*height), width, height], ...
                'HorizontalAlignment', 'left');

            self.runButton = uicontrol( ...
                'Parent', self.blockDetailPanel, ...
                'BackgroundColor', self.lightColor, ...
                'Callback', @(obj, event)self.runCurrentBlock, ...
                'Style', 'pushbutton', ...
                'Units', 'normalized', ...
                'String', 'run', ...
                'Position', [1-inset, 1-(y*height), inset, height], ...
                'HorizontalAlignment', 'left');
            
            y = y+2;
            self.iterationsText = uicontrol( ...
                'Parent', self.blockDetailPanel, ...
                'BackgroundColor', self.lightColor, ...
                'Style', 'text', ...
                'Units', 'normalized', ...
                'String', 'iterations', ...
                'Position', [inset, 1-(y*height), width, height], ...
                'HorizontalAlignment', 'left');
            
            y = y+3;
            self.blockBeginFcnText = uicontrol( ...
                'Parent', self.blockDetailPanel, ...
                'BackgroundColor', self.lightColor, ...
                'Style', 'text', ...
                'Units', 'normalized', ...
                'String', 'block:start', ...
                'Position', [inset, 1-(y*height), width, 2*height], ...
                'HorizontalAlignment', 'left');
            
            y = y+2.2;
            self.blockActionFcnText = uicontrol( ...
                'Parent', self.blockDetailPanel, ...
                'BackgroundColor', self.lightColor, ...
                'Style', 'text', ...
                'Units', 'normalized', ...
                'String', 'block:action', ...
                'Position', [inset, 1-(y*height), width, 2*height], ...
                'HorizontalAlignment', 'left');
            
            y = y+2.2;
            self.blockEndFcnText = uicontrol( ...
                'Parent', self.blockDetailPanel, ...
                'BackgroundColor', self.lightColor, ...
                'Style', 'text', ...
                'Units', 'normalized', ...
                'String', 'block:end', ...
                'Position', [inset, 1-(y*height), width, 2*height], ...
                'HorizontalAlignment', 'left');
            
            y = y+2;
            self.userDataText = uicontrol( ...
                'Parent', self.blockDetailPanel, ...
                'BackgroundColor', self.lightColor, ...
                'Style', 'text', ...
                'Units', 'normalized', ...
                'String', 'userData', ...
                'Position', [inset, 1-(y*height), width, height], ...
                'HorizontalAlignment', 'left');
        end
        
        function displayDetailsForBlock(self, block)
            self.currentBlockTree = block;
            
            set(self.nameText, 'String', block.name, ...
                'ForegroundColor', self.getColorForString(block.name));
            
            method = stringifyValue(block.iterationMethod);
            set(self.iterationsText, 'String', sprintf('%d iterations -- %s', block.iterations, method), ...
                'ForegroundColor', [0 0 0]);
            
            group = sprintf('%s:start', block.name);
            fcn = summarizeFcn(block.blockBeginFcn);
            set(self.blockBeginFcnText, 'String', sprintf('%s = %s', group, fcn), ...
                'ForegroundColor', self.getColorForString(group));
            
            group = sprintf('%s:action', block.name);
            fcn = summarizeFcn(block.blockActionFcn);
            set(self.blockActionFcnText, 'String', sprintf('%s = %s', group, fcn), ...
                'ForegroundColor', self.getColorForString(group));
            
            group = sprintf('%s:end', block.name);
            fcn = summarizeFcn(block.blockEndFcn);
            set(self.blockEndFcnText, 'String', sprintf('%s = %s', group, fcn), ...
                'ForegroundColor', self.getColorForString(group));
            
            data = stringifyValue(block.userData);
            set(self.userDataText, 'String', sprintf('userData = %s', data), ...
                'ForegroundColor', [0 0 0]);
        end
        
        function runCurrentBlock(self)
            self.currentBlockTree.run;
        end
        
        function repopulateBlocksGrid(self)
            % delete all listeners and controls
            self.deleteListeners;
            self.blocksGrid.deleteAllControls;
            
            self.blockTreeCount = 1;
            depth = 1;
            self.addBlockAtDepth(self.topLevelBlockTree, depth);
            self.blocksGrid.repositionControls;
        end
        
        function addBlockAtDepth(self, block, depth);
            % add this block
            row = self.blockTreeCount;
            col = self.getColorForString(block.name);
            h = self.blocksGrid.newControlAtRowAndColumn( ...
                row, [0 1]+depth, ...
                'Style', 'pushbutton', ...
                'String', block.name, ...
                'Callback', @(obj, event) self.displayDetailsForBlock(block), ...
                'ForegroundColor', col);
            
            % listen to this block
            self.listenToBlockTree(block);
            
            % recur on children
            for ii = 1:length(block.children)
                self.blockTreeCount = self.blockTreeCount + 1;
                self.addBlockAtDepth(block.children(ii), depth+1);
            end
        end
        
        function repondToResize(self, figure, event)
            % attempt to resize with characters, rather than normalized
            self.blocksGrid.repositionControls;
        end
        
        function listenToBlockTree(self, block)
            props = properties(block);
            n = self.blockTreeCount;
            for ii = 1:length(props)
                self.listeners(n).(props{ii}) = block.addlistener( ...
                    props{ii}, 'PostSet', ...
                    @(source, event)self.hearBlockPropertyChange(source, event));
            end
            
            self.listeners(n).BlockBegin = block.addlistener( ...
                'BlockBegin', ...
                @(source, event)self.hearBlockBegin(source, event));
        end
        
        function hearBlockPropertyChange(self, metaProp, event)
            % rebuild when tree structure or name changes
            if any(strcmp(metaProp.Name, {'children', 'parent', 'name'}))
                self.repopulateBlocksGrid;
            end
            
            % redraw for currently detailed block
            if event.AffectedObject == self.currentBlockTree
                self.displayDetailsForBlock(self.currentBlockTree);
            end
        end
        
        function hearBlockBegin(self, block, event)
            self.displayDetailsForBlock(block);
        end
    end
end