import 'package:get/get.dart';
import 'package:orange_ui/service/extention/list_extension.dart';
import 'package:orange_ui/utils/asset_res.dart';

import 'countries_model.dart';

class SelectCountryController extends GetxController {
  List<Country> allCountries = [];
  List<CountryState> allStates = [];
  List<City> allCities = [];

  RxList<Country> filteredCountries = <Country>[].obs;
  Rx<Country?> selectedCountry = Rx(null);

  List<CountryState> selectedStatesFromCountry = [];
  RxList<CountryState> filteredStates = <CountryState>[].obs;
  Rx<CountryState?> selectedState = Rx(null);

  List<City> selectedCitiesFromState = [];
  RxList<City> filteredCities = <City>[].obs;
  Rx<City?> selectedCity = Rx(null);

  @override
  void onReady() async {
    super.onReady();
    await Future.delayed(const Duration(milliseconds: 300));
    await _loadData();
  }

  Future<void> _loadData() async {
    allCountries = await parseCountries(filePath: AssetRes.countries);
    allStates = await parseStates(filePath: AssetRes.states);
    filteredCountries.value = allCountries;
  }

  void selectCountry({required Country country}) {
    selectedCountry.value = country;
    selectedStatesFromCountry =
        getStatesByCountryCode(allStates, country.countryCode);
    filteredStates.value = selectedStatesFromCountry;
    filteredCities.clear();
    selectedCity.value = null;
    selectedState.value = null;
  }

  void selectState({required CountryState state}) async {
    selectedState.value = state;
    if (allCities.isEmpty) {
      allCities = await parseCities(filePath: AssetRes.cities);
    }
    // Filter by both countryCode and stateCode so cities are accurate to the selected country & state
    selectedCitiesFromState = getCitiesByStateAndCountry(
      allCities,
      state.stateCode,
      countryCode: state.countryCode,
    );
    if (selectedCitiesFromState.isEmpty) {
      selectedCitiesFromState = getCitiesByStateCode(allCities, state.stateCode);
    }
    filteredCities.value = selectedCitiesFromState;
    selectedCity.value = null;
  }

  void selectCity({required City city}) {
    selectedCity.value = city;
  }

  void searchCountry(String query) {
    filteredCountries.value = allCountries.search(
        query, (model) => model.countryName, (model) => model.countryCode);
  }

  void searchState(String query) {
    filteredStates.value = selectedStatesFromCountry.search(
        query, (model) => model.name, (model) => model.stateCode);
  }

  void searchCity(String query) {
    filteredCities.value =
        selectedCitiesFromState.search(query, (model) => model.name);
  }
}
