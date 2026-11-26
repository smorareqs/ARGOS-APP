import 'package:argos_app/core/errors/failure_mapper.dart';
import 'package:flutter/material.dart';

/// Mensaje corto abajo (reemplaza al anterior).
void showToast(BuildContext context, String message) => ScaffoldMessenger.of(context)
  ..hideCurrentSnackBar()
  ..showSnackBar(SnackBar(content: Text(message)));

/// El motivo de un error en palabras para el usuario.
String errorMessage(Object error) => mapExceptionToFailure(error).message;
