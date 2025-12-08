class FilterOptions {
  String? batchYear;
  String? branch;
  String? semester;
  String? faceRegistration;
  String? attendance;

  FilterOptions({
    this.batchYear,
    this.branch,
    this.semester,
    this.faceRegistration,
    this.attendance,
  });

  int get activeFilterCount {
    int count = 0;
    if (batchYear != null) count++;
    if (branch != null) count++;
    if (semester != null) count++;
    if (faceRegistration != null) count++;
    if (attendance != null) count++;
    return count;
  }

  void reset() {
    batchYear = null;
    branch = null;
    semester = null;
    faceRegistration = null;
    attendance = null;
  }
}
