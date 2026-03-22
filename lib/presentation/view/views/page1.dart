import 'package:dpt_movil/config/configServicio.dart';
import 'package:dpt_movil/config/routes/app_rutas.dart';
import 'package:dpt_movil/data/api/fabrica/ConexionFabricaAbstracta.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Page1 extends StatefulWidget {
  const Page1({super.key});

  @override
  State<StatefulWidget> createState() => _FormularioState();
}

//TODO: quitar este page cuando este un servidor en linea estable

class _FormularioState extends State<Page1> {
  static const String _rutasGuardadasKey = 'rutas_remotas_guardadas';

  final TextEditingController _ipController = TextEditingController();
  List<String> _rutasGuardadas = [];

  @override
  void initState() {
    super.initState();
    _cargarRutasGuardadas();
  }

  @override
  void dispose() {
    _ipController.dispose();
    super.dispose();
  }

  Future<void> _cargarRutasGuardadas() async {
    final preferencias = await SharedPreferences.getInstance();
    final rutas = preferencias.getStringList(_rutasGuardadasKey) ?? [];

    if (!mounted) {
      return;
    }

    setState(() {
      _rutasGuardadas = rutas;
      if (rutas.isNotEmpty) {
        _ipController.text = rutas.first;
      }
    });
  }

  Future<void> _guardarRuta(String ruta) async {
    final rutaNormalizada = ruta.trim();
    if (rutaNormalizada.isEmpty) {
      return;
    }

    final nuevasRutas =
        [
          rutaNormalizada,
          ..._rutasGuardadas.where(
            (rutaActual) => rutaActual != rutaNormalizada,
          ),
        ].take(3).toList();

    final preferencias = await SharedPreferences.getInstance();
    await preferencias.setStringList(_rutasGuardadasKey, nuevasRutas);

    if (!mounted) {
      return;
    }

    setState(() {
      _rutasGuardadas = nuevasRutas;
      _ipController.text = rutaNormalizada;
    });
  }

  Future<void> _iniciarModoRemoto() async {
    final ip = _ipController.text.trim();
    if (ip.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ingresa una direccion antes de continuar'),
        ),
      );
      return;
    }

    await _guardarRuta(ip);
    ConfigServicio.tipoFabricaServicio =
        ConexionFabricaAbstracta.SERVICIO_REMOTO;
    ConfigServicio.servicioFalso = false;
    ConfigServicio.ip = ip;

    if (!mounted) {
      return;
    }

    Navigator.pushNamed(context, AppRutas.categorias);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Modo Ejecucion')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 10),
              child: _modoRemoto(),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 10),
              child: _fakeServidor(),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 10),
              child: _localServidor(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _localServidor() {
    return Column(
      children: [
        const Text('Servidor local', style: TextStyle(fontSize: 25)),
        ElevatedButton(
          onPressed: () {
            ConfigServicio.servicioFalso = false;
            ConfigServicio.tipoFabricaServicio =
                ConexionFabricaAbstracta.SERVICIO_LOCAL;
            Navigator.pushNamed(context, AppRutas.categorias);
          },
          child: const Text('Iniciar con servicio local'),
        ),
      ],
    );
  }

  Widget _fakeServidor() {
    return Column(
      children: [
        const Text('Servidor Falso', style: TextStyle(fontSize: 25)),
        ElevatedButton(
          onPressed: () {
            ConfigServicio.servicioFalso = true;
            Navigator.pushNamed(context, AppRutas.categorias);
          },
          child: const Text('Iniciar con servidor falso'),
        ),
      ],
    );
  }

  Widget _modoRemoto() {
    return Column(
      children: [
        const Text('Ejecucion Remota', style: TextStyle(fontSize: 25)),
        TextField(
          controller: _ipController,
          decoration: const InputDecoration(
            labelText: 'Direccion IP o ruta',
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.url,
        ),
        if (_rutasGuardadas.isNotEmpty) ...[
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            decoration: const InputDecoration(
              labelText: 'Ultimas rutas usadas',
              border: OutlineInputBorder(),
            ),
            items:
                _rutasGuardadas
                    .map(
                      (ruta) => DropdownMenuItem<String>(
                        value: ruta,
                        child: Text(ruta, overflow: TextOverflow.ellipsis),
                      ),
                    )
                    .toList(),
            onChanged: (rutaSeleccionada) {
              if (rutaSeleccionada == null) {
                return;
              }

              setState(() {
                _ipController.text = rutaSeleccionada;
              });
            },
          ),
        ],
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: _iniciarModoRemoto,
          child: const Text('Iniciar con servicio remoto'),
        ),
      ],
    );
  }
}
