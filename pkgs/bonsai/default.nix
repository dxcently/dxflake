{
  lib,
  stdenv,
  fetchFromGitHub,
  cmake,
  ninja,
  pkg-config,
  openssl,
  rocmPackages,
}:

stdenv.mkDerivation {
  pname = "bonsai-llama-cpp";
  version = "prism-b10709-9a9394a";

  src = fetchFromGitHub {
    owner = "PrismML-Eng";
    repo = "llama.cpp";
    rev = "9a9394a895b96003ca842a6041cb28ac49a108f7";
    hash = "sha256-KDecY+v9S/193mLGse5EsJPugZR1wxWzOlOU7GuMd5Y=";
  };

  nativeBuildInputs = [
    cmake
    ninja
    pkg-config
  ];

  buildInputs = [
    openssl
    rocmPackages.clr
    rocmPackages.hipblas
    rocmPackages.rocblas
  ];

  cmakeFlags = [
    "-DGGML_HIP=ON"
    "-DGGML_NATIVE=OFF"
    "-DBUILD_SHARED_LIBS=OFF"
    "-DCMAKE_HIP_COMPILER=${rocmPackages.clr.hipClangPath}/clang++"
    "-DCMAKE_HIP_ARCHITECTURES=gfx1102"
    "-DAMDGPU_TARGETS=gfx1102"
    "-DGPU_TARGETS=gfx1102"
    "-DLLAMA_BUILD_SERVER=ON"
    "-DLLAMA_BUILD_TESTS=OFF"
    "-DLLAMA_BUILD_EXAMPLES=OFF"
    "-DLLAMA_BUILD_TOOLS=ON"
    "-DLLAMA_BUILD_APP=OFF"
    "-DLLAMA_BUILD_UI=OFF"
    "-DLLAMA_USE_PREBUILT_UI=OFF"
    "-DLLAMA_OPENSSL=OFF"
    "-DLLAMA_TOOLS_INSTALL=ON"
    "-DCMAKE_BUILD_TYPE=Release"
  ];

  # Only the trial entry points are needed; cap compilation at eight jobs so
  # the desktop and its 8 GiB GPU are not crowded by unrelated tools.
  buildPhase = ''
    cmake --build . --target llama-cli llama-server llama-bench -j8
  '';

  # Keep only the three trial entry points in the public output. Static
  # linking avoids exporting upstream-named libraries and CMake metadata that
  # would collide with nixpkgs' llama-cpp when both are installed.
  installPhase = ''
    mkdir -p "$out/bin"
    cp bin/llama-cli "$out/bin/bonsai-cli"
    cp bin/llama-server "$out/bin/bonsai-server"
    cp bin/llama-bench "$out/bin/bonsai-bench"
  '';

  # This trial is intentionally a runtime package: the upstream test suite
  # builds many unrelated tools and does not exercise the HIP Bonsai path.
  doCheck = false;

  meta = {
    description = "PrismML Bonsai2 llama.cpp fork with HIP support";
    homepage = "https://github.com/PrismML-Eng/llama.cpp";
    license = lib.licenses.mit;
    mainProgram = "bonsai-cli";
    platforms = [ "x86_64-linux" ];
  };
}
