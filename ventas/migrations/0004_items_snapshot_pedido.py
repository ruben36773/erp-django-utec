# ventas/migrations/0004_ensure_items_snapshot.py
from django.db import migrations


def ensure_column(apps, schema_editor):
    connection = schema_editor.connection
    table = "ventas_pedido"

    with connection.cursor() as cursor:
        columns = [
            col.name
            for col in connection.introspection.get_table_description(cursor, table)
        ]

    if "items_snapshot" in columns:
        return  # Ya existe (SQLite local, o Postgres ya corregido)

    Pedido = apps.get_model("ventas", "Pedido")
    field = Pedido._meta.get_field("items_snapshot")
    schema_editor.add_field(Pedido, field)


class Migration(migrations.Migration):

    dependencies = [
        ("ventas", "0003_items_snapshot_pedido"),
    ]

    operations = [
        migrations.RunPython(ensure_column, migrations.RunPython.noop),
    ]