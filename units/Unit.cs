using Godot;
using System.Collections.Generic;

public partial class Unit : CharacterBody2D
{
    [Export] PackedScene PROJECTILE = (PackedScene)ResourceLoader.Load("res://projectiles/Bullet.tscn");

    public const float SPEED = 150.0f;
    public const int ATTACK_RANGE = 30;
    public const int HP_MAX = 100;

    public static readonly Dictionary<int, string> FACING_MAPPING = new Dictionary<int, string>()
    {
        { 1, "right" },
        { 2, "down" },
        { 3, "left" },
        { 4, "up" },
    };

    enum States
    {
        IDLE,
        WALKING,
        ATTACKING,
    }

    [Export] public int playerId = 1;

    [Export] int hp = 75;

    [Export] int facing = 2;
    public Unit target;
    [Export] States state = States.IDLE;

    [Export] bool isSelected = false;

    Sprite2D selectedCircle;
    Vector2 destination;

    [Export] public Unit targetUnit;


    public bool followCursor = false;

    public void _ready()
    {
        destination = Position;
        selectedCircle = GetNode<Sprite2D>("SelectedCircle");

        target = this;
        targetUnit = this;

        AddToGroup("units");
        selectedCircle.Visible = isSelected;
        GetNode<ProgressBar>("HealthBar").Value = hp;
    }

    public void set_selected(bool flag)
    {
        isSelected = flag;
        selectedCircle.Visible = flag;
    }

    public void _process(double delta)
    {
        GetNode<ProgressBar>("HealthBar").Value = hp;

        if (IsMultiplayerAuthority())
        {
            if (state == States.ATTACKING)
            {
            }
            else if (Velocity.IsZeroApprox())
            {
                state = States.IDLE;
            }
            else
            {
                state = States.WALKING;
            }
        }

        if (Mathf.Abs(Velocity.X) >= Mathf.Abs(Velocity.Y))
        {
            if (Velocity.X > 0)
            {
                facing = 1;
            }
            else if (Velocity.X < 0)
            {
                facing = 3;
            }
        }
        else if (Mathf.Abs(Velocity.Y) > Mathf.Abs(Velocity.X))
        {
            if (Velocity.Y < 0)
            {
                facing = 4;
            }
            else if (Velocity.Y > 0)
            {
                facing = 2;
            }
        }

        if (state == States.ATTACKING)
        {
            GetNode<AnimatedSprite2D>("AnimatedSprite2D").Animation = "attack_" + FACING_MAPPING[facing];
        }
        else if (state == States.WALKING)
        {
            GetNode<AnimatedSprite2D>("AnimatedSprite2D").Animation = "walk_" + FACING_MAPPING[facing];
        }
        else if (state == States.IDLE)
        {
            GetNode<AnimatedSprite2D>("AnimatedSprite2D").Animation = "idle_" + FACING_MAPPING[facing];
        }
    }

    public void move_to(Vector2 _destination)
    {
        destination = _destination;
        followCursor = true;
    }

    public void _physics_process(double delta)
    {
        if (IsMultiplayerAuthority())
        {
            if (followCursor)
            {
                GetNode<NavigationAgent2D>("NavigationAgent2D").TargetPosition = destination;
            }

            if (GetNode<NavigationAgent2D>("NavigationAgent2D").IsTargetReachable())
            {
                var destinationNext = GetNode<NavigationAgent2D>("NavigationAgent2D").GetNextPathPosition();

                Velocity = Position.DirectionTo(destinationNext).Normalized() * SPEED;
                GetNode<NavigationAgent2D>("NavigationAgent2D").SetVelocity(Velocity);

                if (Position.DistanceTo(destination) < 15)
                {
                    Velocity = Vector2.Zero;
                    followCursor = false;
                }
            }

            MoveAndSlide();
        }
    }

    public void damage(int amount = 1)
    {
        hp -= amount;
        GetNode<ProgressBar>("HealthBar").Value = hp;
        GetNode<AudioStreamPlayer2D>("DamageSound").Play();
    }

    public void attack(int damage = 5)
    {
        damage = 5;
        state = States.ATTACKING;
        GetNode<Timer>("AttackTimer").Start();
        Bullet newProjectile = PROJECTILE.Instantiate<Bullet>();
        newProjectile.Position = Position;
        newProjectile.target = targetUnit;
        newProjectile.damage = damage;
        GetParent().GetParent().AddChild(newProjectile);
    }

    public void _on_attack_timer_timeout()
    {
        state = States.IDLE;
    }
}
