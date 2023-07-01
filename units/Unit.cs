using System.Collections.Generic;
using Godot;
using Godot.Collections;

public partial class Unit : CharacterBody2D
{
    PackedScene PROJECTILE = (PackedScene)ResourceLoader.Load("res://projectiles/Weapon.tscn");
    PackedScene PROJECTILE_SWORD = (PackedScene)ResourceLoader.Load("res://projectiles/Sword.tscn");
    List<PackedScene> weapons = new ();
    private PackedScene weaponEquipped;

    public const float SPEED = 150.0f;
    // public const int ATTACK_RANGE = 200;
    public const int HP_MAX = 100;

    public static readonly System.Collections.Generic.Dictionary<int, string> FACING_MAPPING = new System.Collections.Generic.Dictionary<int, string>()
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


    private bool followCursor = false;

    private void _ready()
    {
        weapons.Add(PROJECTILE);
        weapons.Add(PROJECTILE_SWORD);
        weaponEquipped = weapons[1];

        destination = Position;
        selectedCircle = GetNode<Sprite2D>("SelectedCircle");

        target = this;
        targetUnit = null;

        AddToGroup("units");
        selectedCircle.Visible = isSelected;
        GetNode<ProgressBar>("HealthBar").Value = hp;
    }

    public void set_selected(bool flag)
    {
        isSelected = flag;
        selectedCircle.Visible = flag;
    }

    private void _process(double delta)
    {
        GetNode<Label>("Label").Text = $"{playerId.ToString()}  {state}";
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

        GetNode<AnimatedSprite2D>("AnimatedSprite2D").Animation = state switch
        {
            States.ATTACKING => "attack_" + FACING_MAPPING[facing],
            States.WALKING => "walk_" + FACING_MAPPING[facing],
            States.IDLE => "idle_" + FACING_MAPPING[facing],
            _ => GetNode<AnimatedSprite2D>("AnimatedSprite2D").Animation
        };
    }

    public void moveTo(Vector2 _destination)
    {
        destination = _destination;
        followCursor = true;
    }

    private void _physics_process(double delta)
    {
        if (!IsMultiplayerAuthority()) return;

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

        if (targetUnit != null && state == States.IDLE && Position.DistanceTo(targetUnit.Position) <= weaponEquipped.Instantiate<Weapon>().range)
        {
            attack();
        }
    }

    public void damage(int amount = 1)
    {
        hp -= amount;
        GetNode<ProgressBar>("HealthBar").Value = hp;
        GetNode<AudioStreamPlayer2D>("DamageSound").Play();
    }

    private void attack()
    {
        state = States.ATTACKING;
        GetNode<Timer>("AttackTimer").Start();
        Weapon newProjectile = weaponEquipped.Instantiate<Weapon>();
        newProjectile.Position = Position;
        newProjectile.target = targetUnit;
        // newProjectile.damage = damage;
        GetParent().GetParent().AddChild(newProjectile);
    }

    private void _on_attack_timer_timeout()
    {
        state = States.IDLE;
    }
}
