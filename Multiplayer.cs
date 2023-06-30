using System;
using System.Linq;
using Godot;
using Dictionary = Godot.Collections.Dictionary;
using Array = Godot.Collections.Array;


public partial class Multiplayer : Node
{
    PackedScene PLAYER = (PackedScene)ResourceLoader.Load("res://Player.tscn");
    PackedScene PLAYER_LABEL = (PackedScene)ResourceLoader.Load("res://PlayerLabel.tscn");

    public const int PORT = 4433;

    public void _process(double delta)
    {
        var allPlayers = GetNode("Players").GetChildren().OfType<Player>();
        Array allPlayerIds = new Array() { };
        foreach (var player in allPlayers)
        {
            allPlayerIds.Add(player.playerId);
        }
    }

    public void _ready()
    {
        //	get_tree().paused = true;
        // Multiplayer.server_relay = false;  //TODO: Disable server_relay
        if (DisplayServer.GetName() == "headless")
        {
            GD.Print("Automatically starting dedicated server.");
            // _on_host_pressed.call_deferred();  //TODO
            CallDeferred("_on_host_pressed");
        }
    }

    public void _on_host_pressed()
    {
        // Start game as server
        var peer = new ENetMultiplayerPeer();
        peer.CreateServer(PORT);
        // if (peer.GetConnectionStatus() == MultiplayerPeer.CONNECTION_DISCONNECTED)  //TODO
        // {
        //     OS.alert("Failed to start multiplayer server.");
        //     GD.Print("Failed to start multiplayer server.");
        //     return;
        // }

        Multiplayer.MultiplayerPeer = peer;
        //	start_game()
    }

    public void _on_connect_pressed()
    {
        // Start game as client, && join existing host
        String txt = GetNode<LineEdit>("UI/Options/Joining/Remote").Text;
        if (txt == "")
        {
            OS.Alert("Need a remote to connect to.");
            return;
        }

        var peer = new ENetMultiplayerPeer();
        peer.CreateClient(txt, PORT);
        // if (peer.GetConnectionStatus() == MultiplayerPeer.CONNECTION_DISCONNECTED)  //TODO
        // {
        //     OS.alert("Failed to start multiplayer client.");
        //     return;
        // }

        Multiplayer.MultiplayerPeer = peer;
        //	start_game()
    }

    public void start_game()
    {
        GetNode<Control>("UI").Hide();
        GD.Print("Game started");
        GetTree().Paused = false;

        int playerd2id = 1;

        if (Multiplayer.IsServer())
        {
            //		Multiplayer.peer_connected.connect(add_player)
            //		Multiplayer.peer_disconnected.connect(delete_player)

            foreach (var id in Multiplayer.GetPeers())
            {
                add_player(id);
                GD.Print($"Added peer player {id}.");
                playerd2id = id;
            }

            if (!OS.HasFeature("dedicated_server"))
            {
                add_player(1);
                GD.Print("Not dedicated server. Added player 1.");
            }
        }

        GetNode<Unit>("../Dungeon/Units/Unit3").playerId = playerd2id;


        foreach (var player in GetNode("Players").GetChildren())
        {
            var playerLabelNode = PLAYER_LABEL.Instantiate();
            // playerLabelNode.playerId = player.playerId;  //TODO
            // playerLabelNode.playerName = player.name;
            // playerLabelNode.playerColor = player.playerColor;
            GetNode("PanelContainer/PlayerList").AddChild(playerLabelNode, true);
        }
    }

    public void _on_start_game_pressed()
    {
        start_game();
    }

    public void add_player(int id)
    {
        var playerNode = PLAYER.Instantiate<Player>();
        playerNode.playerId = id;
        playerNode.Name = id.ToString();
        GetNode("Players").AddChild(playerNode, true);
    }
}
