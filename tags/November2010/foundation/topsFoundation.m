classdef topsFoundation < handle
    % @class topsFoundation
    % Superclass for all of the funtamental Tower of Psych classes.
    % @details
    % The topsFoundation superclass provides a common interface for Tower
    % of Psych classes.  This includes naming cell array manipulation, and
    % generating graphical interfaces.
    % @ingroup foundation
    
    properties (SetObservable)
        % a string name to indentify the object
        name = '';
    end
    
    methods
        % Make a topsGUI graphical interface for this object.
        % @details
        % Subclasses may overrride to return a specific topsGUI subclass,
        % or let topsFoundataion generate a generic topsGUI.
        function g = gui(self)
            g = topsGUI;
            g.title = class(self);
            p = self.guiPanel(g);
        end
        
        % Make a topsDetailPanel with details about this object.
        % @param parentGUI a topsGUI to contain the new panel
        % @param position optional normalized [x y w h] where to locate the
        % new panel within @a parentGUI
        % @details
        % Subclasses may overrride to return a specific topsDetailPanel
        % subclass, or let topsFoundataion generate a generic
        % topsValuePanel.
        function p = guiPanel(self, varargin)
            p = topsValuePanel(varargin{:});
            p.populateWithValueDetails(self);
        end
    end
    
    methods (Static)
        % Add an item to a cell array.
        % @param c a cell array
        % @param item any item to add to the cell array @a c
        % @param index optional index where to insert @a item
        % @details
        % add() inserts @a item into @a c at the given @a index.  If no
        % @a index is given, add() appends @a item to the end of @a c.
        % @details
        % Returns the modified cell array @a c.  May also return the index
        % into @a c where @a item was inserted.
        function [c, index] = cellAdd(c, item, index)
            l = length(c) + 1;
            if nargin < 3 || isempty(index)
                index = l;
            end
            
            modified = cell(1, l);
            selector = false(1, l);
            selector(index) = true;
            modified{selector} = item;
            modified(~selector) = c;
            c = modified;
        end
        
        % Does a cell array conatin an item?
        % @param c a cell array
        % @param item any item that might be in @a c
        % @details
        % Returns a logical array the same size as c, which is true where
        % elements of @a c are equal to @a item.
        % @details
        % cellContains() compares items for equality using Matlab's
        % built-in eq() when it can, or else isequal().
        function selector = cellContains(c, item)
            itemMayEq = ismethod(item, 'eq');
            selector = false(size(c));
            for ii = 1:numel(c)
                if itemMayEq && ismethod(c{ii}, 'eq')
                    comparison = @eq;
                else
                    comparison = @isequal;
                end
                selector(ii) = feval(comparison, item, c{ii});
            end
        end
        
        % Remove an item from a cell array.
        % @param c a cell array
        % @param item an item to remove from @a c
        % @details
        % Removes all elements of @a c that are equal to the given @a item.
        % @details
        % Returns the modified cell array, @a c.
        function c = cellRemoveItem(self, item)
            selector = self.contains(item);
            c = c(~selector);
        end
    end
end