using Godot;

public partial class Bullet : StaticBody2D
{
    [Export]
    int speed = 500;
    public int damage = 1;
    public CharacterBody2D target = null;

    public override void _PhysicsProcess(double delta)
    {
        if (target != null)
        {
            Rotation = Position.AngleToPoint(target.Position);
            var direction = Position.DirectionTo(target.Position);
            Position += direction * (float)(speed * delta);
        }
    }

    private void _on_area_2d_body_entered(Unit body)
    {
        if (body == target)
        {
            body.damage(damage);
            QueueFree();
        }
    }
}
