using Godot;
using System.Collections.Generic;
using System.Linq;

public partial class Game : Node
{
    public void _physics_process(double delta)
    {
        GD.Print("hello");

        List<Player> players = GetNode("Multiplayer/Players").GetChildren().OfType<Player>().ToList();
        List<Unit> units = (List<Unit>)GetNode("Dungeon/Units").GetChildren().OfType<Unit>().ToList();

        GD.Print(players);

        foreach (var player in players)
        {
            GD.Print(player.selectedUnitIds);
            GD.Print(player.isIssuingMoveOrder);
            if (player.isIssuingMoveOrder)
            {
                foreach (var unitId in player.selectedUnitIds)
                {
                    Unit unit = (Unit)InstanceFromId((ulong)unitId);
                    if (unit.playerId == player.playerId)
                    {
                        unit.move_to(player.destination);
                        if (player.targetedUnitId != 0)
                        {
                            unit.targetUnit = (Unit)InstanceFromId(player.targetedUnitId);
                        }
                    }
                }

                player.isIssuingMoveOrder = false;
            }

            if (player.isIssuingAttackOrder)
            {
                foreach (var unitId in player.selectedUnitIds)
                {
                    var unit = (Unit)InstanceFromId((ulong)unitId);
                    unit.attack();
                }

                player.isIssuingAttackOrder = false;
            }
        }
    }
}
