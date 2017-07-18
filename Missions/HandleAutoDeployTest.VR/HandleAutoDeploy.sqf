/*
	Made by Rockhount - HandleAutoDeploy Script v1.3 (SP/MP & HC compatible)
	More Info at: https://github.com/Rockhount/ArmA3_Script_HandleAutoDeploy
	Errors will be written into the rpt and starts with "HandleAutoDeploy Error:"
	Call:
	[["B_HMG_01_A_weapon_F","B_GMG_01_high_F",150,3],["O_HMG_01_high_weapon_F","O_GMG_01_high_F",150,3], ...] execVM "HandleAutoDeploy.sqf";
	"B_HMG_01_A_weapon_F" = Classname of the backpack
	"B_GMG_01_high_F" = Classname of the static weapon
	150 = Scan radius to search for other static weapons of the same type
	3 = Max allowed number of other manned static weapons of the same type in the given radius (0 = Deactivation of this feature)
	
	The backpacks of all existing units get scanned 10 seconds after this script has been called. If the backpack can be
	find in the script parameters, then the unit gets a loop as long as he lives. The unit gets queried wheter or not he
	is in a "COMBAT" Modus. If he is, then he builds automaticly the static weapon with an animation. If the radius-scan
	feature is used, then the number of deployed weapons within the given radius around it is limited to the	selected max
	value. The static weapon will get undeployed only, if the unit is no longer in a "COMBAT" Modus or 10 minutes have elapsed.
	-------------------------------------------------------------------------------------------------------------------------
	Gemacht von Rockhount - HandleAutoDeploy Skript v1.3 (SP/MP & HC Kompatibel)
	Mehr Infos unter: https://github.com/Rockhount/ArmA3_Script_HandleAutoDeploy
	Fehler werden in die RPT geschrieben und starten mit "HandleAutoDeploy Error:"
	Aufruf:
	[["B_HMG_01_A_weapon_F","B_GMG_01_high_F",150,3],["O_HMG_01_high_weapon_F","O_GMG_01_high_F",150,3], ...] execVM "HandleAutoDeploy.sqf";
	"B_HMG_01_A_weapon_F" = Klassenname des des Rucksacks
	"B_GMG_01_high_F" = Klassenname der statischen Waffe
	150 = Radius wo nach anderen statischen Stellungen des selben Typs gesucht wird
	3 = Maximale Anzahl der erlaubten statischen bemannten Waffen des selben Typs im vorgegebenen Radius (0 = Deaktivierung des Features)
	
	10 Sekunden nachdem der Skript aufgerufen wurde, werden alle Einheiten, die existieren, nach ihrem Rucksack abgefragt.
	Wenn der Rucksack in eines der Skriptparameter zu finden ist, dann bekommt diese Einheit solange sie lebt eine Schleife.
	In der Schleife wird abgefragt, ob sich die Einheit im Kampf befindet. Wenn sie sich im "COMBAT" Modus befindet, dann baut
	sie automatisch mit einer Animation die statische Waffe auf. Wenn das Feature des Radius-Scanns benutzt wird, dann dürfen
	im vorgegebenen Radius um die Waffe herum nicht mehr als die angegebene Anzahl an Stellungen aufgebaut werden. Die statische
	Waffe wird erst dann wieder abgebaut, wenn sie sich nicht mehr im "COMBAT" Modus befindet oder mindestens 10 Minuten	seit dem
	Aufbau vergangen sind.
*/
if (isServer) then
{
	private _Local_var_Exit = false;
	private _Local_var_Classnames = if ((!isNil "_this") && {typeName _this == "ARRAY"}) then {_this} else {_Local_var_Exit = true;false};
	scopeName "HandleAutoDeployMainScope";
	if (!_Local_var_Exit) then
	{
		{
			if ((typeName _x != "ARRAY") || {count _x != 4}) exitWith
			{
				_Local_var_Exit = true;
			};
			{
				if (typeName _x != "STRING") then
				{
					_Local_var_Exit = true;
					breakTo "HandleAutoDeployMainScope";
				};
			} forEach [_x select 0, _x select 1];
			{
				if (typeName _x != "SCALAR") then
				{
					_Local_var_Exit = true;
					breakTo "HandleAutoDeployMainScope";
				};
			} forEach [_x select 2, _x select 3];
		} forEach _Local_var_Classnames;
	};
	if (isNil "Global_var_HandleAutoDeployCalled") then
	{
		Global_var_HandleAutoDeployCalled = true;
		Global_var_HandleAutoDeployPositions = [];
	}
	else
	{
		"HandleAutoDeploy: Don't run this script twice." remoteExec ["systemChat", 0, false];
		diag_log "HandleAutoDeploy Error: Don't run this script twice.";
		_Local_var_Exit = true;
	};
	if (_Local_var_Exit) exitWith
	{
		diag_log "HandleAutoDeploy Error: Wrong parameter";
	};
	if (!canSuspend) exitWith 
	{
		diag_log "HandleAutoDeploy Error: This script does not work in an unscheduled environment";
	};
	sleep 10;
	{
		private _Local_var_Soldier = _x;
		{
			if ((backpack _Local_var_Soldier) == (_x select 0)) exitWith
			{
				[_Local_var_Soldier, _x select 0, _x select 1, _x select 2, _x select 3] spawn
				{
					Params ["_Local_var_Soldier", "_Local_var_BackpackClassname","_Local_var_VehicleClassName","_Local_var_Radius","_Local_var_MaxCount"];
					private _Local_fnc_ScannArea =
					{
						Params ["_Local_var_VehicleClassName","_Local_var_Pos","_Local_var_Radius","_Local_var_MaxCount"];
						if (({((_x select 0) isEqualTo  _Local_var_VehicleClassName) && {(_Local_var_Pos distance2D (_x select 1)) < _Local_var_Radius}} count Global_var_HandleAutoDeployPositions) >= _Local_var_MaxCount) then
						{
							sleep 30;
							false
						}
						else
						{
							true
						};
					};
					while	{!(isNull _Local_var_Soldier) && {alive _Local_var_Soldier}} do
					{
						waitUntil{sleep 5;(!(isNull _Local_var_Soldier) && {alive _Local_var_Soldier} && {(behaviour _Local_var_Soldier) == "COMBAT"} && {(_Local_var_MaxCount == 0) || {[_Local_var_VehicleClassName, getPos _Local_var_Soldier, _Local_var_Radius, _Local_var_MaxCount] call _Local_fnc_ScannArea}}) || {isNull _Local_var_Soldier} || {!alive _Local_var_Soldier}};
						if (!(isNull _Local_var_Soldier) && {alive _Local_var_Soldier}) then
						{
							private _Local_var_CurDeployPos = [_Local_var_VehicleClassName, getPos _Local_var_Soldier];
							Global_var_HandleAutoDeployPositions pushBack _Local_var_CurDeployPos;
							removeBackpackGlobal _Local_var_Soldier;
							[_Local_var_Soldier,"Acts_TerminalOpen"] remoteExec ["switchMove", 0, false];
							sleep 30;
							private _Local_var_Vehicle = createVehicle [_Local_var_VehicleClassName, getPos _Local_var_Soldier, [], 0, "NONE"];
							_Local_var_Vehicle setDir (getDir _Local_var_Soldier);
							_Local_var_Soldier assignAsGunner _Local_var_Vehicle;
							[_Local_var_Soldier,_Local_var_Vehicle] remoteExec ["moveInGunner", _Local_var_Soldier, false];
							_Local_var_Vehicle lock true;
							private _Local_var_Time = time + 600;
							waitUntil{sleep 5; (!(isNull _Local_var_Soldier) && {alive _Local_var_Soldier} && {(behaviour _Local_var_Soldier) != "COMBAT"}) || {time > _Local_var_Time}};
							if (!(isNull _Local_var_Soldier) && {alive _Local_var_Soldier} && {!isNil "_Local_var_Vehicle"} && {!isNull _Local_var_Vehicle} && {alive _Local_var_Vehicle}) then
							{
								_Local_var_Vehicle lock false;
								private _Local_var_CurDir = getdir _Local_var_Vehicle;
								moveOut _Local_var_Soldier;
								_Local_var_Vehicle lock true;
								[_Local_var_Soldier,"MOVE"] remoteExec ["disableAI", _Local_var_Soldier, false];
								[_Local_var_Soldier,"Acts_TerminalOpen"] remoteExec ["switchMove", 0, false];
								sleep 30;
								[_Local_var_Soldier,_Local_var_BackpackClassname] remoteExec ["addBackpack", _Local_var_Soldier, false];
								deleteVehicle _Local_var_Vehicle;
								[_Local_var_Soldier,""] remoteExec ["switchMove", 0, false];
								[_Local_var_Soldier,"MOVE"] remoteExec ["enableAI", _Local_var_Soldier, false];
							};
							Global_var_HandleAutoDeployPositions = Global_var_HandleAutoDeployPositions - [_Local_var_CurDeployPos];
						};
					};
				};
			};
		} forEach _Local_var_Classnames;
	} forEach ((allUnits - allPlayers) - allDeadMen);
};