function [gameTree, gameList] = encounter
%Test/Demonstrate the Tower of Psych (tops) foundation classes with a game
%
%   [gameTree, gameList] = encounter
%
%   "encounter" is a game.  It's a simplified homage to the battle seqences
%   in the popular "Final Fantasy" Nintendo games.  You, the player,
%   control several characters with different speeds and attack powers.
%   Your job is to defeat monsters (by clicking on them) before they defeat
%   you.
%
%   "encounter" is a first attempt at integrating the various control and
%   data structures that make up the "Tower of Psych", or "tops".  tops is
%   a code project that aims to facilitate the design and running of
%   psychophysics experimetns in Matlab.
%
%   gameTree is an instance of topsBlockTree.  It organizes several
%   randomly selected battle sequences.
%
%   gameList is an instance of topsGroupedList.  It contains all of the data
%   and objects used in the encounter game.
%
%   To play encounter, type the following:
%   [gameTree, gameList] = encounter;
%   gameTree.run;
%
%   For more details about tops, and about tops concepts as implemented in
%   this "encounter" demo, read "encounter-as-tops-demo.rtf".
%
%   See also encounter-as-tops-demo.rtf

% copyright 2009 by benjamin.heasly@gmail.com, Seattle, WA

% topsDataLog is a singleton class that logs data
%   clear any old data
topsDataLog.flushAllData;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Section 1: create, organize, and return objects
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% top-level data object, add arbitrary parameters
gameList = topsGroupedList;


% top-level control object
%   with functions defined below
gameTree = topsBlockTree;
gameTree.name = 'encounter';
gameTree.blockStartFevalable = {@gameSetup, gameList};
gameTree.blockEndFevalable = {@gameTearDown, gameList};
gameList.addItemToGroupWithMnemonic(gameTree, 'game', 'gameTree');


% low-level control loop object
%   with functions defined below
battleLoop = topsFunctionLoop;
battleLoop.addFunctionToGroupWithRank({@drawnow}, 'battle', 1);
battleLoop.addFunctionToGroupWithRank({@checkBattleStatus, gameList, battleLoop}, 'battle', 6);
gameList.addItemToGroupWithMnemonic(battleLoop, 'game', 'battleLoop');


% low-level function queues for character and monster attacks
%   add dispatch method to function queue
monsterQueue = EncounterBattleQueue;
characterQueue = EncounterBattleQueue;
gameList.addItemToGroupWithMnemonic(monsterQueue, 'game', 'monsterQueue');
gameList.addItemToGroupWithMnemonic(characterQueue, 'game', 'characterQueue');
battleLoop.addFunctionToGroupWithRank({@()monsterQueue.dispatchNextFevalable}, 'battle', 5);
battleLoop.addFunctionToGroupWithRank({@()characterQueue.dispatchNextFevalable}, 'battle', 2);


% Create an array of battler objects to represent player characters. 
%   add character array to the gameList
%   create a wake-up timers for character
%   add each timer to the function loop
Goonius = EncounterBattler;
Goonius.name = 'Goonius';
Goonius.attackInterval = 15;
Goonius.attackMean = 10;
Goonius.maxHp = 50;
Goonius.restoreHp;

Jet = EncounterBattler;
Jet.name = 'Jet';
Jet.attackInterval = 5;
Jet.attackMean = 2;
Jet.maxHp = 50;
Jet.restoreHp;

Hero = EncounterBattler;
Hero.name = 'Hero';
Hero.attackInterval = 5;
Hero.attackMean = 10;
Hero.maxHp = 10;
Hero.restoreHp;

characters = [Goonius, Jet, Hero];
gameList.addItemToGroupWithMnemonic(characters, 'game', 'characters');
gameList.addItemToGroupWithMnemonic({}, 'game', 'activeCharacter');

for ii = 1:length(characters)
    bt = EncounterBattleTimer;
    charTimers(ii) = bt;
    bt.loadForRepeatIntervalWithCallback ...
        (characters(ii).attackInterval, {@characterWakesUp, characters(ii), gameList});
    battleLoop.addFunctionToGroupWithRank({@()bt.tick}, 'charTimers', 3+(ii/10));
end
gameList.addItemToGroupWithMnemonic(charTimers, 'game', 'charTimers');


% Create battler objects to reperesent several types of monster
%   make several arrays with interesting groups of monsters
%   add each monster group to the gameList
%   create wake-up timers for monsters in each group
%   add each timer to the function loop
isMonster = true;

Evil = EncounterBattler(isMonster);
Evil.name = 'Evil Hero';
Evil.attackInterval = 5;
Evil.attackMean = 7;
Evil.maxHp = 1;
Evil.restoreHp;

Fool = EncounterBattler(isMonster);
Fool.name = 'Fool';
Fool.attackInterval = 10;
Fool.attackMean = 0.5;
Fool.maxHp = 5;
Fool.restoreHp;

Boxer = EncounterBattler(isMonster);
Boxer.name = 'Boxer';
Boxer.attackInterval = 3;
Boxer.attackMean = 1;
Boxer.maxHp = 20;
Boxer.restoreHp;

Robot = EncounterBattler(isMonster);
Robot.name = 'Iron Robot';
Robot.attackInterval = 15;
Robot.attackMean = 10;
Robot.maxHp = 100;
Robot.restoreHp;

% group monsters into several overlapping groups, 
%   add groups top-level grouped list object
%   create a game subblock for each group, add to top-level block tree
group(1).name = 'fools';
group(1).monsters = [Fool.copy, Fool.copy, Fool.copy, Fool.copy];
group(2).name = 'robot';
group(2).monsters = Robot.copy;
group(3).name = 'bizzaro';
group(3).monsters = [Evil.copy, Boxer.copy, Fool.copy, Evil.copy, Boxer.copy, Fool.copy];
group(4).name = 'dojo';
group(4).monsters = [Evil.copy, Boxer.copy, Boxer.copy, Boxer.copy, Boxer.copy, Boxer.copy];
group(5).name = 'ambush';
group(5).monsters = [Hero.copy];

for ii = 1:length(group)
    loopName = sprintf('%sTimers', group(ii).name);
    groupTimers = EncounterBattleTimer.empty;
    for jj = 1:length(group(ii).monsters)
        bt = EncounterBattleTimer;
        groupTimers(jj) = bt;
        bt.loadForRepeatIntervalWithCallback ...
            (group(ii).monsters(jj).attackInterval, {@monsterWakesUp, group(ii).monsters(jj), gameList});
        battleLoop.addFunctionToGroupWithRank({@()bt.tick}, loopName, 4+(jj/10));
    end
    gameList.addItemToGroupWithMnemonic(group(ii).monsters, 'monsters', group(ii).name);
    gameList.addItemToGroupWithMnemonic(groupTimers, 'monsterTimers', group(ii).name);
    
    % concatenate loop modes specially for this monster group
    battleLoop.mergeGroupsIntoGroup({'battle', 'charTimers', loopName}, group(ii).name);
    
    battleBlock = topsBlockTree;
    battleBlock.name = group(ii).name;
    battleBlock.blockStartFevalable = {@battleSetup, battleBlock, gameList};
    battleBlock.blockActionFevalable = {@battleGo, battleBlock, gameList};
    battleBlock.blockEndFevalable = {@battleTearDown, battleBlock, gameList};
    gameTree.addChild(battleBlock);
end
gameList.addItemToGroupWithMnemonic('', 'game', 'activeMonsterGroup');


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Section 2: define functions for game behavior
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function gameSetup(gameList)
% create the GUI
f = figure('MenuBar', 'none', 'ToolBar', 'none', ...
    'Name', 'Encounter!', 'NumberTitle', 'off');
gameList.addItemToGroupWithMnemonic(f, 'game', 'figure');
ax = axes('Parent', f, ...
    'Box', 'on', ...
    'XTick', [], 'YTick', [], ...
    'XLim', [0 1], 'YLim', [0 1], ...
    'Units', 'normalized', ...
    'Position', [.05 .475, .9, .5]);
gameList.addItemToGroupWithMnemonic(ax, 'game', 'axes');

% add characters to GUI
characters = gameList.getItemFromGroupWithMnemonic('game', 'characters');
nChars = length(characters);
for ii = 1:nChars
    axesPos = subposition([0 0 1 1], nChars, nChars+1, ii, nChars+1);
    characters(ii).restoreHp;
    characters(ii).makeGraphicsForAxesAtPositionWithCallback(ax, axesPos, []);
    figurePos = subposition([.05 .025, .9, .4], 2, ceil(nChars/2), ceil(ii/2), mod(ii-1, 2)+1);
    observeProperties(characters(ii), f, figurePos);
end


function battleSetup(battleBlock, gameList)
% position monsters in axes
groupName = battleBlock.name;
monsterGroup = gameList.getItemFromGroupWithMnemonic('monsters', groupName);
characters = gameList.getItemFromGroupWithMnemonic('game', 'characters');
nChars = length(characters);
for ii = 1:nChars
    characters(ii).hideHighlight;
end
gameList.addItemToGroupWithMnemonic({}, 'game', 'activeCharacter');
ax = gameList.getItemFromGroupWithMnemonic('game', 'axes');
for ii = 1:length(monsterGroup)
    monsterGroup(ii).restoreHp;
    axesPos = subposition([0 0 1 1], nChars, nChars+1, mod(ii-1, nChars)+1, ceil(ii/nChars));
    cb = @(source, event) characterSelectVictim(source, event, gameList);
    monsterGroup(ii).makeGraphicsForAxesAtPositionWithCallback(ax, axesPos, cb);
end
gameList.addItemToGroupWithMnemonic(groupName, 'game', 'activeMonsterGroup');
characterQueue = gameList.getItemFromGroupWithMnemonic('game', 'characterQueue');
characterQueue.isLocked = false;


function battleGo(battleBlock, gameList)
groupName = battleBlock.name;
charTimers = gameList.getItemFromGroupWithMnemonic('game', 'charTimers');
monsterTimers = gameList.getItemFromGroupWithMnemonic('monsterTimers', groupName);
monsterQueue = gameList.getItemFromGroupWithMnemonic('game', 'monsterQueue');
monsterQueue.flushQueue;
for t = [charTimers, monsterTimers]
    t.beginRepetitions;
end
battleLoop = gameList.getItemFromGroupWithMnemonic('game', 'battleLoop');
battleLoop.runForGroup(groupName, 600);


function characterWakesUp(character, gameList)
% enqueue self to become active character
characterQueue = gameList.getItemFromGroupWithMnemonic('game', 'characterQueue');
characterQueue.addFevalable({@characterBecomesTheActiveCharacter, character, gameList});


function characterBecomesTheActiveCharacter(character, gameList)
% freeze the queue to have one active character at a time
characterQueue = gameList.getItemFromGroupWithMnemonic('game', 'characterQueue');
characterQueue.isLocked = true;
character.showHighlight;
gameList.addItemToGroupWithMnemonic(character, 'game', 'activeCharacter');


function characterSelectVictim(monsterGraphic, event, gameList)
% let active character, if any, attack
activeCharacter = gameList.getItemFromGroupWithMnemonic('game', 'activeCharacter');
if ~isempty(activeCharacter)
    battlerAttacksBattler(activeCharacter, get(monsterGraphic, 'UserData'));
    % unfreeze the queue for the next active character
    characterQueue = gameList.getItemFromGroupWithMnemonic('game', 'characterQueue');
    characterQueue.isLocked = false;
end


function monsterWakesUp(monster, gameList)
characters = gameList.getItemFromGroupWithMnemonic('game', 'characters');
alive = find(~[characters.isDead]);
if ~isempty(alive)
    victim = characters(alive(ceil(rand*length(alive))));
    monsterQueue = gameList.getItemFromGroupWithMnemonic('game', 'monsterQueue');
    monsterQueue.addFevalable({@battlerAttacksBattler, monster, victim});
end


function battlerAttacksBattler(attacker, victim)
attacker.showHighlight;
attacker.attackOpponent(victim);
pause(.5)
victim.hideDamage;
attacker.hideHighlight;


function checkBattleStatus(gameList, battleLoop)
% prevent eternal locking of characterQueue
activeCharacter = gameList.getItemFromGroupWithMnemonic('game', 'activeCharacter');
if ~isempty(activeCharacter) && activeCharacter.isDead
    characterQueue = gameList.getItemFromGroupWithMnemonic('game', 'characterQueue');
    characterQueue.isLocked = false;
end
% check if all characters are dead
characters = gameList.getItemFromGroupWithMnemonic('game', 'characters');
if all([characters.isDead])
    battleLoop.proceed = false;
    disp('Anihiliation!')
end
% check if all monsters are dead
groupName = gameList.getItemFromGroupWithMnemonic('game', 'activeMonsterGroup');
monsterGroup = gameList.getItemFromGroupWithMnemonic('monsters', groupName);
if all([monsterGroup.isDead])
    battleLoop.proceed = false;
    disp('Victory!')
end


function battleTearDown(battleBlock, gameList)
% clear monster group from axes
groupName = battleBlock.name;
monsterGroup = gameList.getItemFromGroupWithMnemonic('monsters', groupName);
for ii = 1:length(monsterGroup)
    monsterGroup(ii).deleteGraphics;
end


function gameTearDown(gameList)
characters = gameList.getItemFromGroupWithMnemonic('game', 'characters');
nChars = length(characters);
for ii = 1:length(nChars)
    characters(ii).deleteGraphics;
end
f = gameList.getItemFromGroupWithMnemonic('game', 'figure');
close(f)