import 'package:csv/csv.dart';
import 'package:flutter/services.dart';

class Country {
  String countryCode;
  String countryName;
  String phoneCode;

  Country({
    required this.countryCode,
    required this.countryName,
    required this.phoneCode,
  });

  @override
  String toString() {
    return 'Country(countryCode: $countryCode, countryName: $countryName, phoneCode: $phoneCode)';
  }
}

class CountryState {
  String name;
  String countryCode;
  String stateCode;

  CountryState({
    required this.name,
    required this.countryCode,
    required this.stateCode,
  });

  @override
  String toString() {
    return 'State(name: $name, countryCode: $countryCode, stateCode: $stateCode)';
  }
}

class City {
  String name;
  String countryCode;
  String stateCode;

  City({
    required this.name,
    this.countryCode = '',
    required this.stateCode,
  });

  @override
  String toString() {
    return 'City(name: $name, countryCode: $countryCode, stateCode: $stateCode)';
  }
}

// Helper Functions
Future<List<T>> parseCsv<T>(
  String filePath,
  T Function(List<dynamic> row) factoryFunction,
) async {
  final content = await rootBundle.loadString(filePath);

  final rows = csv.decode(content);
  return rows.skip(1).map((row) => factoryFunction(row)).toList();
}

Future<List<Country>> parseCountries({required String filePath}) {
  return parseCsv(
    filePath,
    (row) => Country(
      countryCode: row[0],
      countryName: row[1],
      phoneCode: row[2] is int ? '+${row[2]}' : row[2],
    ),
  );
}

Future<List<CountryState>> parseStates({required String filePath}) {
  return parseCsv(
    filePath,
    (row) => CountryState(
      name: row[0],
      countryCode: row[1],
      stateCode: row[2] is int ? '${row[2]}' : row[2],
    ),
  );
}

Future<List<City>> parseCities({required String filePath}) async {
  return await parseCsv(
    filePath,
    (row) {
      if (row.length >= 3) {
        return City(
          name: '${row[0]}',
          countryCode: '${row[1]}',
          stateCode: row[2] is int ? '${row[2]}' : '${row[2]}',
        );
      } else {
        return City(
          name: '${row[0]}',
          countryCode: '',
          stateCode: row[1] is int ? '${row[1]}' : '${row[1]}',
        );
      }
    },
  );
}

// Search Functions
List<CountryState> getStatesByCountryCode(
    List<CountryState> states, String countryCode) {
  return states.where((state) => state.countryCode == countryCode).toList();
}

List<City> getCitiesByStateAndCountry(
    List<City> cities, String stateCode, {String? countryCode}) {
  return cities.where((city) {
    if (city.stateCode != stateCode) return false;
    if (countryCode != null &&
        countryCode.isNotEmpty &&
        city.countryCode.isNotEmpty) {
      return city.countryCode.toUpperCase() == countryCode.toUpperCase();
    }
    return true;
  }).toList();
}

List<City> getCitiesByStateCode(List<City> cities, String stateCode) {
  return cities.where((city) => city.stateCode == stateCode).toList();
}
