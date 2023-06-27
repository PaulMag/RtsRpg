using Godot;
using Array = Godot.Collections.Array;
using System.Linq;
using System.Collections.Generic;

public partial class Player : Node
{
	 
	[Export] public int playerId = 0;
	[Export] public string playerName = "";
	[Export] public Color playerColor;
	
	[Export] public Vector2 direction  = new Vector2();
	[Export] public Array selectedUnitIds = new Array(){};
	[Export] public Vector2 destination = Vector2.Zero;
	[Export] public ulong targetedUnitId;
	
	[Export] public bool isCloning = false;
	[Export] public bool isIssuingMoveOrder = false;
	[Export] public bool isIssuingAttackOrder = false;
	
	public const int SELECTION_BOX_MINIMUM_SIZE = 5;

	public List<Unit> allUnits = new List<Unit>() { };
	public bool isDraggingMouse = false;
	public bool isSelecting = false;
	public bool isTargeting = false;
	public Vector2 selectionStart = new Vector2();
	public Vector2 selectionEnd = new Vector2();

	Panel panel;
	Area2D selectionDetector;
	CollisionShape2D collisionShape;
	
	public void _ready()
	{  
		playerId = Name.ToString().ToInt();
		playerColor = new Color(GD.Randf(), GD.Randf(), GD.Randf());
		SetMultiplayerAuthority(playerId);
		SetProcess(GetMultiplayerAuthority() == Multiplayer.GetUniqueId());
		if(Multiplayer.IsServer())
		{
			GD.Print($"Player on server: {playerId}   '{Name}'");
		}
		else
		{
			GD.Print($"Player on peer: {playerId}   '{Name}'");
		}

		panel = GetNode<Panel>("Panel");
		selectionDetector = GetNode<Area2D>("SelectionDetector");
		collisionShape = GetNode<CollisionShape2D>("SelectionDetector/CollisionShape2D");
	}
	
	public void _process(double delta)
	{
		if(isDraggingMouse)
		{
			draw_selection_box();
		}
		direction = Input.GetVector("ui_left", "ui_right", "ui_up", "ui_down");
		if(Input.IsActionJustPressed("ui_cancel"))
		{
			//clone.rpc();  //TODO: Figure out RPC
		}
	}

	//TODO: Figure out RPC
	//@rpc("call_local")
	public void clone()
	{  
		isCloning = true;
	
	}
	//TODO: Figure out RPC
	//@rpc("call_local")
	[Rpc(TransferMode = MultiplayerPeer.TransferModeEnum.Reliable)]
	public void issueMoveOrder()
	{  
		isIssuingMoveOrder = true;
	
	}
	//TODO: Figure out RPC
	//@rpc("call_local")
	public void issueAttackOrder()
	{  
		isIssuingAttackOrder = true;
	}
	
	public void area_selected(Vector2 start, Vector2 end)
	{
		Vector2 area_start = new Vector2(Mathf.Min(start.X, end.X), Mathf.Min(start.Y, end.Y));
		Vector2 area_end = new Vector2(Mathf.Max(start.X, end.X), Mathf.Max(start.Y, end.Y));
		set_selection_area(area_start, area_end);
	}
	
	public void _input(InputEvent @event)
	{  
		if(@event.IsActionPressed("mouse_left_click"))
		{
			selectionStart = panel.GetGlobalMousePosition();
			isDraggingMouse = true	;
			panel.Visible = true;
		}
		if(isDraggingMouse)
		{
			selectionEnd = panel.GetGlobalMousePosition();
		}
		if(@event.IsActionReleased("mouse_left_click"))
		{
			selectionEnd = panel.GetGlobalMousePosition();
			isDraggingMouse = false;
			panel.Visible = false;
			area_selected(selectionStart, selectionEnd);
			
		}
		if(@event.IsActionPressed("mouse_right_click"))
		{
			destination = panel.GetGlobalMousePosition();
			set_target_area(destination);
			//TODO: Figure out RPC
			//issueMoveOrder.rpc();
			isIssuingMoveOrder = true;
		}
		if (@event.IsActionPressed("ui_accept"))
		{
			//TODO: Figure out RPC
			//issueAttackOrder.rpc();
		}
	}
	
	public void _on_selection_timer_timeout()
	{  
		isSelecting = false;
		collisionShape.Disabled  = true;
	
	}
	
	public void set_selection_area(Vector2 start, Vector2 end)
	{
		allUnits = GetTree().GetNodesInGroup("units").OfType<Unit>().ToList();
		foreach(var unit in allUnits)
		{
			unit.set_selected(false);
		}

		selectedUnitIds = new Array(){};
		isSelecting = true;
		collisionShape.Disabled  = false;
		selectionDetector.Position = (start + end) * 0.5f;

		float scaleModifier = 0.05f;  //TODO: Do this properly.
		collisionShape.Scale = new Vector2(Mathf.Abs(start.X - end.X) * scaleModifier, Mathf.Abs(start.Y - end.Y) * scaleModifier);

		GetNode<Timer>("SelectionTimer").Start();
	
	}
	
	public void _on_selection_detector_area_entered(Area2D area)
	{
		GD.Print(area);

		if(isSelecting)
		{
			var unit = area.GetParent<Unit>();
			GD.Print(unit);
			unit.set_selected(true);
			selectedUnitIds.Append(unit.GetInstanceId());
			GD.Print(selectedUnitIds);
			//TODO: Should select according to z_index ordering
			Vector2 boxShape = (selectionStart - selectionEnd).Abs();
			if(boxShape.X + boxShape.Y < SELECTION_BOX_MINIMUM_SIZE)
			{
				isSelecting = false;
				collisionShape.Disabled  = true;
	
			}
		}
	}
	
	public void draw_selection_box(bool s=true)
	{  
		panel.Size = new Vector2(Mathf.Abs(selectionStart.X - selectionEnd.X), Mathf.Abs(selectionStart.Y - selectionEnd.Y));
		Vector2 pos = new Vector2();
		pos.X = Mathf.Min(selectionStart.X, selectionEnd.X);
		pos.Y = Mathf.Min(selectionStart.Y, selectionEnd.Y);
		panel.Position = pos;
		panel.Size *= s ? 1 : 0;
	}
	
	public void set_target_area(Vector2 position)
	{  
		//TODO: Do this properly.
		allUnits = (List<Unit>)GetTree().GetNodesInGroup("units").OfType<Unit>().ToList();
		foreach (Unit unit in allUnits)
		{
			if(position.DistanceTo(unit.Position) < 12)
			{
				targetedUnitId = unit.GetInstanceId();
				return;
			}
		}
	}
	
	
	
}
