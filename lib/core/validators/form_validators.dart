class FormValidators {
  FormValidators._();

  static String? required(String? value, [String message = 'Field ini wajib diisi']) {
    if (value == null || value.trim().isEmpty) {
      return message;
    }
    return null;
  }

  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email wajib diisi';
    }
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    if (!emailRegex.hasMatch(value.trim())) {
      return 'Format email tidak valid';
    }
    return null;
  }

  static String? password(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password wajib diisi';
    }
    if (value.length < 6) {
      return 'Password minimal 6 karakter';
    }
    return null;
  }

  static String? confirmPassword(String? value, String originalPassword) {
    if (value == null || value.isEmpty) {
      return 'Konfirmasi password wajib diisi';
    }
    if (value != originalPassword) {
      return 'Konfirmasi password tidak cocok';
    }
    return null;
  }

  static String? whatsapp(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Nomor WhatsApp wajib diisi';
    }
    final clean = value.replaceAll(RegExp(r'\D'), '');
    if (clean.length < 10 || clean.length > 15) {
      return 'Nomor WhatsApp tidak valid (10-15 digit)';
    }
    if (!clean.startsWith('08') && !clean.startsWith('628')) {
      return 'Gunakan format nomor Indonesia (08... atau 628...)';
    }
    return null;
  }

  static String? nik(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'NIK wajib diisi';
    }
    final clean = value.trim();
    if (!RegExp(r'^\d{16}$').hasMatch(clean)) {
      return 'NIK harus tepat 16 digit angka';
    }
    return null;
  }

  static int calculateAge(DateTime birthDate) {
    final now = DateTime.now();
    int age = now.year - birthDate.year;
    if (now.month < birthDate.month ||
        (now.month == birthDate.month && now.day < birthDate.day)) {
      age--;
    }
    return age;
  }

  static String? teacherAge(DateTime? birthDate) {
    if (birthDate == null) {
      return 'Tanggal lahir wajib diisi';
    }
    final age = calculateAge(birthDate);
    if (age > 35) {
      return 'Usia guru maksimal 35 tahun (saat ini $age tahun)';
    }
    if (age < 18) {
      return 'Usia guru minimal 18 tahun (saat ini $age tahun)';
    }
    return null;
  }

  static String? pdfFileSize(int? sizeBytes, [int maxMegaBytes = 5]) {
    if (sizeBytes == null || sizeBytes <= 0) {
      return 'Dokumen PDF wajib dilampirkan';
    }
    final maxBytes = maxMegaBytes * 1024 * 1024;
    if (sizeBytes > maxBytes) {
      return 'Ukuran file PDF maksimal $maxMegaBytes MB';
    }
    return null;
  }

  static String? englishLevel(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Level bahasa Inggris wajib dipilih';
    }
    final clean = value.toUpperCase();
    if (!clean.contains('B2') && !clean.contains('C1') && !clean.contains('C2')) {
      return 'Level bahasa Inggris minimal CEFR B2';
    }
    return null;
  }
}
