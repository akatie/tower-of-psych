classdef topsGroupedListPanel < handle
    % @class topsGroupedListPanel
    % Resuable 3-column view for topsGroupedLists in topsGUI interfaces.
    % @details
    % Many interface classes, not just topsGroupedListGUI, need to present
    % controls for interacting with topsGroupedList objects.
    % topsGroupedListPanel supports topsGroupedList interactions as a
    % uipanel within any topsGUI subclass.
    % @details
    % topsGroupedListPanel relies on its parentGUI, an instance of topsGUI
    % or a subclass, to function.  It's not able to function independently
    % like a regular uipanel.
    % @ingroup foundataion
    
    properties
        % topsGUI that contains this panel
        parentGUI;
        
        % normalized [x y w h] where to locate this panel in parentGUI
        position = [0 0 1 1 ];
        
        % uipanel to hold topsGroupedList controls
        panel;
        
        % topsGroupedList to interact with
        groupedList;
        
        % string or number identifying the currently selected group
        currentGroup;
        
        % string or number identifying the currently selected mnemonic
        currentMnemonic;
        
        % true or false, whether the GUI allows editing of list items
        itemsAreEditable = false;
    end
    
    properties (Hidden)
        % string title for the "groups" column at left
        groupString = 'group:';
        
        % uicontrol label for the "groups" column at left
        groupLabel;
        
        % ScrollingControlGrid for the "groups" column at left
        groupsGrid;
        
        % string title for the "mnemonics" column in the middle
        mnemonicString = 'mnemonic:';
        
        % uicontrol label for the "mnemonics" column in the middle
        mnemonicLabel;
        
        % ScrollingControlGrid for the "mnemonics" column in the middle
        mnemonicsGrid;
        
        % string title for the "item" column at right
        itemString = 'item:';
        
        % uicontrol label for the "item" column at right
        itemLabel;
        
        % uicontrol button to send the current item to the base workspace
        itemToWorkspaceButton;
        
        % ScrollingControlGrid for the "item" column at right
        itemDetailGrid;
    end
    
    methods
        % Constructor takes one optional argument.
        % @param parentGUI a topsGUI to contains this panel
        % @param position normalized [x y w h] where to locate the new
        % panel in @a parentGUI
        % @details
        % Returns a handle to the new topsGroupedListPanel.  If
        % @a parentGUI is missing, the panel will be empty.
        function self = topsGroupedListPanel(parentGUI, position)
            if nargin
                self.parentGUI = parentGUI;
            end
            
            if nargin == 2
                self.position = position;
            end
            
            self.createWidgets;
        end
        
        % Populate this panel with the contents of a topsGroupedList.
        % @param groupedList a topsGroupedList object to interact with
        % @details
        % Fills in this panel's controls  with data from the given @a
        % groupedList, and binds the controls to interact with @a
        % groupedList.  If this panel's itemsAreEditable is true, the
        % controls will allow editing of items in @a groupedList.
        function populateWithGroupedList(self, groupedList)
            self.groupedList = groupedList;
            self.listenToGroupedList(groupedList);
            self.repopulateGroupsGrid;
        end
        
        % Create a new ui panel and add unpopulated controls to it.
        function createWidgets(self)
            if isempty(self.parentGUI) || ~ishandle(self.parentGUI.figure)
                return
            end
            f = self.parentGUI.figure;
            
            if ishandle(self.panel)
                delete(self.panel)
            end
            self.panel = uipanel( ...
                'Parent', f, ...
                'BorderType', 'line', ...
                'BorderWidth', 1, ...
                'ForegroundColor', get(f, 'Color'), ...
                'HighlightColor', get(f, 'Color'), ...
                'Title', '', ...
                'BackgroundColor', 'none', ...
                'Units', 'normalized', ...
                'Position', self.position, ...
                'Clipping', 'on', ...
                'HandleVisibility', 'on', ...
                'HitTest', 'on', ...
                'SelectionHighlight', 'off', ...
                'Visible', 'on');
            
            left = 0;
            right = 1;
            bottom = 0;
            top = 1;
            yDiv = .95;
            width = (1/3);
            self.groupLabel = uicontrol( ...
                'Parent', self.panel, ...
                'Style', 'text', ...
                'Units', 'normalized', ...
                'String', self.groupString, ...
                'Position', [left, yDiv, width, top-yDiv], ...
                'HorizontalAlignment', 'left');
            
            % custom widget class, in tops/utilities
            self.groupsGrid = ScrollingControlGrid( ...
                self.panel, [left, bottom, width, yDiv-bottom]);
            self.parentGUI.addScrollableChild(self.groupsGrid.panel, ...
                {@ScrollingControlGrid.respondToSliderOrScroll, ...
                self.groupsGrid});
            
            self.mnemonicLabel = uicontrol( ...
                'Parent', self.panel, ...
                'Style', 'text', ...
                'Units', 'normalized', ...
                'String', self.mnemonicString, ...
                'Position', [width, yDiv, width, top-yDiv], ...
                'HorizontalAlignment', 'left');
            
            self.mnemonicsGrid = ScrollingControlGrid( ...
                self.panel, [width, bottom, width, yDiv-bottom]);
            self.parentGUI.addScrollableChild(self.mnemonicsGrid.panel, ...
                {@ScrollingControlGrid.respondToSliderOrScroll, ...
                self.mnemonicsGrid});
            
            self.itemLabel = uicontrol( ...
                'Parent', self.panel, ...
                'Style', 'text', ...
                'Units', 'normalized', ...
                'String', self.itemString, ...
                'Position', [right-width, yDiv, width/2, top-yDiv], ...
                'HorizontalAlignment', 'left');
            
            itemToBase = @(obj, event)self.currentItemToBaseWorkspace;
            self.itemToWorkspaceButton = uicontrol( ...
                'Parent', self.panel, ...
                'Callback', itemToBase, ...
                'Style', 'pushbutton', ...
                'Units', 'normalized', ...
                'String', 'to workspace', ...
                'Position', [right-width/2, yDiv, width/2, top-yDiv], ...
                'HorizontalAlignment', 'left');
            
            self.itemDetailGrid = ScrollingControlGrid( ...
                self.panel, [right-width, bottom, width, yDiv-bottom]);
            self.parentGUI.addScrollableChild(self.itemDetailGrid.panel, ...
                {@ScrollingControlGrid.respondToSliderOrScroll, ...
                self.itemDetailGrid});
            self.itemDetailGrid.rowHeight = 1.5;
        end
        
        function setCurrentGroup(self, group, button)
            self.currentGroup = group;
            self.repopulateMnemonicsGrid;
            if nargin > 2
                topsText.toggleOff(self.groupsGrid.controls);
                topsText.toggleOn(button);
                drawnow;
            end
        end
        
        function setCurrentMnemonic(self, mnemonic, button)
            self.currentMnemonic = mnemonic;
            self.showDetailsForCurrentItem;
            if nargin > 2
                topsText.toggleOff(self.mnemonicsGrid.controls);
                topsText.toggleOn(button);
                drawnow;
            end
        end
        
        function repopulateGroupsGrid(self)
            groups = self.groupedList.groups;
            self.groupsGrid.deleteAllControls;
            for ii = 1:length(groups)
                cb = @(obj, event)self.setCurrentGroup(groups{ii}, obj);
                self.addGridButton( ...
                    self.groupsGrid, ii, groups{ii}, cb);
            end
            self.groupsGrid.repositionControls;
            if ~isempty(groups)
                button = self.groupsGrid.controls(1,1);
                self.setCurrentGroup(groups{1}, button);
            end
        end
        
        function repopulateMnemonicsGrid(self)
            mnemonics = self.groupedList.getAllMnemonicsFromGroup( ...
                self.currentGroup);
            self.mnemonicsGrid.deleteAllControls;
            for ii = 1:length(mnemonics)
                cb = @(obj, event)self.setCurrentMnemonic(mnemonics{ii}, obj);
                self.addGridButton( ...
                    self.mnemonicsGrid, ii, mnemonics{ii}, cb);
            end
            self.mnemonicsGrid.repositionControls;
            if ~isempty(mnemonics)
                button = self.mnemonicsGrid.controls(1,1);
                self.setCurrentMnemonic(mnemonics{1}, button);
            end
        end
        
        function addGridButton(self, grid, row, name, callback)
            toggle = topsText.toggleText;
            lookFeel = self.parentGUI.getLookAndFeelForValue(name);
            interactive = {'Callback', callback};
            grid.newControlAtRowAndColumn( ...
                row, 1, ...
                toggle{:}, ...
                lookFeel{:}, ...
                interactive{:});
        end
        
        function args = getModalControlArgs(self, group, mnemonic, item, refPath)
            if self.itemsAreEditable
                if nargin < 5 || isempty(refPath)
                    subs = [];
                else
                    subs = substruct(refPath{:});
                end
                
                getter = {@topsGroupedListPanel.getValueOfListItem, ...
                    self.groupedList, group, mnemonic, subs};
                setter = {@topsGroupedListPanel.setValueOfListItem, ...
                    self.groupedList, group, mnemonic, subs};
                
                args = self.parentGUI.getEditableUIControlArgsWithGetterAndSetter(...
                    getter, setter);
                
            else
                args = self.parentGUI.getInteractiveUIControlArgsForValue(item);
            end
        end
        
        function showDetailsForCurrentItem(self)
            group = self.currentGroup;
            mnemonic = self.currentMnemonic;
            item = self.groupedList.getItemFromGroupWithMnemonic( ...
                group, mnemonic);
            
            self.itemDetailGrid.deleteAllControls;
            width = 10;
            
            % a shallow summary of all items
            refPath = {};
            args = self.getModalControlArgs( ...
                group, mnemonic, item, refPath);
            self.itemDetailGrid.newControlAtRowAndColumn(1, [1 width], args{:});
            
            % a deeper look at fields and elements of deep items
            if isstruct(item) || isobject(item)
                if isstruct(item)
                    fn = fieldnames(item);
                else
                    fn = properties(item);
                end
                
                row = 1;
                n = numel(item);
                for ii = 1:n
                    % delimiter for each array element
                    row = row+1;
                    refPath(1:2) = {'()',{ii}};
                    delimiter = sprintf('(%d of %d)', ii, n);
                    
                    args = self.getModalControlArgs( ...
                        group, mnemonic, item, refPath);
                    self.itemDetailGrid.newControlAtRowAndColumn( ...
                        row, [1 4], args{:}, 'String', delimiter);
                    
                    for jj = 1:length(fn)
                        % field name and value
                        row = row+1;
                        refPath(3:4) = {'.',fn{jj}};
                        args = self.parentGUI.getDescriptiveUIControlArgsForValue(fn{jj});
                        self.itemDetailGrid.newControlAtRowAndColumn( ...
                            row, [2 width], args{:});
                        
                        row = row+1;
                        args = self.getModalControlArgs( ...
                            group, mnemonic, item(ii).(fn{jj}), refPath);
                        self.itemDetailGrid.newControlAtRowAndColumn( ...
                            row, [2 width], args{:}, 'HorizontalAlignment', 'right');
                    end
                end
                
            elseif iscell(item)
                for ii = 1:numel(item)
                    row = ii + 1;
                    refPath(1:2) = {'{}',{ii}};
                    args = self.getModalControlArgs( ...
                        group, mnemonic, item{ii}, refPath);
                    self.itemDetailGrid.newControlAtRowAndColumn(row, [2 width], args{:});
                end
            end
            self.itemDetailGrid.repositionControls;
        end
        
        % Send the currently displayed item to the base workspace.
        % The "to workspace" button calls this method.  This method then
        % uses Matlab's built-in assignin() to put the currently shown item
        % in the base workspace (i.e. the Command Window).
        % @details
        % When the currently selected mnemonic is a valid variable name,
        % creates or overwrites a variable with that name.  Otherwise,
        % creates or overwrites a variable named "item".  Prints a message
        % about which name was used.
        function currentItemToBaseWorkspace(self)
            item = self.groupedList.getItemFromGroupWithMnemonic( ...
                self.currentGroup, self.currentMnemonic);
            if isvarname(self.currentMnemonic)
                name = self.currentMnemonic;
            else
                name = 'item';
            end
            assignin('base', name, item);
            disp(sprintf('sent "%s" to base workspace', name));
        end
        
        function listenToGroupedList(self, groupedList)
            self.parentGUI.deleteListeners;
            self.parentGUI.listeners.NewAddition = ...
                groupedList.addlistener('NewAddition', ...
                @(source, event)self.hearNewListAddition(source, event));
        end
        
        function hearNewListAddition(self, groupedList, event)
            logEntry = event.userData;
            group = logEntry.group;
            mnemonic = logEntry.mnemonic;
            
            if logEntry.groupIsNew
                row = 1 + size(self.groupsGrid.controls, 1);
                cb = @(obj, event)self.setCurrentGroup(group, obj);
                self.addGridButton( ...
                    self.groupsGrid, row, group, cb);
                self.groupsGrid.repositionControls;
            end
            
            if ~isequal(self.currentMnemonic, mnemonic)
                row = 1 + size(self.mnemonicsGrid.controls, 1);
                cb = @(obj, event)self.setCurrentMnemonic(mnemonic, obj);
                self.addGridButton( ...
                    self.mnemonicsGrid, row, mnemonic, cb);
                self.mnemonicsGrid.repositionControls;
            end
        end
        
        function repondToResize(self, figure, event)
            self.groupsGrid.repositionControls;
            self.mnemonicsGrid.repositionControls;
            self.itemDetailGrid.repositionControls;
        end
    end
    
    methods (Static)
        % Set a value from a GUI control (a callback).
        % @param value a new value to set
        % @param list topsGroupedList that contains the value
        % @param group list group that contains the value
        % @param mnemonic list group mnemonic for the value
        % @param subs substruct-style struct to index the list item
        % (optional)
        % @details
        % Replaces the item in @a list indicated by @a group and @a
        % mnemonic with the given @a value.  If @a subs is not empty,
        % replaces the referenced element or field of the indicated item,
        % rather than the item itself.
        % @details
        % setValueOfListItem() is suitable as a topsText "setter" callback.
        function setValueOfListItem(value, list, group, mnemonic, subs)
            if isempty(subs)
                item = value;
            else
                item = list.getItemFromGroupWithMnemonic(group, mnemonic);
                item = subsasgn(item, subs, value);
            end
            list.addItemToGroupWithMnemonic(item, group, mnemonic);
        end
        
        % Get a value for a GUI control (a callback).
        % @param list topsGroupedList that contains the value
        % @param group list group that contains the value
        % @param mnemonic list group mnemonic for the value
        % @param subs substruct-style struct to index the list item
        % (optional)
        % @details
        % Returns the item in @a list indicated by @a group and @a
        % mnemonic.  If @a subs is not empty, returns the referenced
        % element or field of the indicated item, rather than the item
        % itself.
        % @details
        % getValueOfListItem() is suitable as a topsText "getter" callback.
        function value = getValueOfListItem(list, group, mnemonic, subs)
            if isempty(subs)
                value = list.getItemFromGroupWithMnemonic(group, mnemonic);
            else
                item = list.getItemFromGroupWithMnemonic(group, mnemonic);
                value = subsref(item, subs);
            end
        end
    end
end