
import 'package:chat_app/core/enums/enums.dart';
import 'package:flutter/material.dart';

class BaseViewModel extends ChangeNotifier {
    ViewState _state = ViewState.idle;
    ViewState get state => _state;

    setState(ViewState state) {
      _state = state;
      notifyListeners();
    }

}