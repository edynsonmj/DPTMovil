import 'package:flutter/material.dart';
import 'package:dpt_movil/config/routes/app_rutas.dart';
import 'package:dpt_movil/config/configServicio.dart';
import 'package:dpt_movil/data/api/fabrica/ConexionFabricaAbstracta.dart';
import 'package:dpt_movil/presentation/view/widgets/bar.dart';

class Page1 extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _formularioState();
}

class _formularioState extends State<Page1> {
  final TextEditingController _ipController = TextEditingController();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Modo Ejecucion')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Padding(
                padding: EdgeInsets.symmetric(vertical: 20, horizontal: 10),
                child: ModoRemoto()),
            Padding(
              padding: EdgeInsets.symmetric(vertical: 20, horizontal: 10),
              child: FakeServidor(),
            ),
            Padding(
              padding: EdgeInsets.symmetric(vertical: 20, horizontal: 10),
              child: localServidor(),
            ),
          ],
        ),
      ),
    );
  }

  Widget localServidor() {
    return Column(children: [
      Text(
        'Servidor local',
        style: TextStyle(fontSize: 25),
      ),
      ElevatedButton(
          onPressed: () {
            ConfigServicio.tipoFabricaServicio = ConexionFabricaAbstracta
                .SERVICIO_LOCAL; // Asignar la IP al servicio
            Navigator.pushNamed(context, AppRutas.categorias);
          },
          child: Text('Iniciar con servicio local')),
    ]);
  }

  Widget FakeServidor() {
    return Column(children: [
      Text(
        'Servidor Falso',
        style: TextStyle(fontSize: 25),
      ),
      ElevatedButton(
          onPressed: () {
            final ip = _ipController.text;
            ConfigServicio.servicioFalso = true;
            Navigator.pushNamed(context, AppRutas.categorias);
          },
          child: Text('Iniciar con servidor falso')),
    ]);
  }

  Widget ModoRemoto() {
    return Column(
      children: [
        Text(
          'Ejecucion Remota',
          style: TextStyle(fontSize: 25),
        ),
        TextField(
          controller: _ipController,
          decoration: InputDecoration(
            labelText: 'Dirección IP',
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.number,
        ),
        SizedBox(height: 16),
        ElevatedButton(
          onPressed: () {
            final ip = _ipController.text;
            ConfigServicio.ip = ip; // Asignar la IP al servicio
            Navigator.pushNamed(context, AppRutas.categorias);
          },
          child: Text('Iniciar con servicio remoto'),
        ),
      ],
    );
  }
}
