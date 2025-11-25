Map<String, dynamic> removeEmpty(Map<String, dynamic> data) {
  data.removeWhere(
    (key, value) =>
        value == null ||
        value == "" ||
        (value is List && value.isEmpty) ||
        value == "All",
  );
  return data;
}
