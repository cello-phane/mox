
#!/usr/bin/env bash

set -e

# ============================================================
# Mox -> MinGW OBJ -> GCC -> raylib
# ============================================================

SOURCE_DIR="./examples"
MODULE_NAME="2_raylib.mox"

SOURCE_FILE="$SOURCE_DIR/$MODULE_NAME"
OBJECT_BASE="$SOURCE_DIR/$MODULE_NAME.obj"
OUTPUT_FILE="$SOURCE_DIR/$MODULE_NAME.exe"

RAYLIB_PATH="C:/repos/mox/modules/vendor/raylib/win64_mingw"
RAYLIB_DLL="$RAYLIB_PATH/raylib.dll"

W64DEVKIT="C:/repos/w64devkit"

GCC="gcc"
MOX_EXE="./mox.exe"
# ------------------------------------------------------------
# 1. Compile Mox -> MinGW COFF objects
# ------------------------------------------------------------

rm -f "$OBJECT_BASE".*.obj

echo
echo "============================================"
echo " Compiling Mox -> MinGW COFF OBJ"
echo "============================================"

$MOX_EXE \
    backend=llvm \
    llvm_out_format=obj \
    compile="$SOURCE_FILE" \
    out="$OBJECT_BASE" \
    linker=""

# ------------------------------------------------------------
# 2. Collect generated object files
# ------------------------------------------------------------
OBJECT_FILES=""

for file in "$SOURCE_DIR"/"$MODULE_NAME".obj.*.obj; do
    if [ -f "$file" ]; then
        OBJECT_FILES="$OBJECT_FILES $file"
    fi
done

if [ -z "$OBJECT_FILES" ]; then
    echo "Error: No Mox object files were generated."
    exit 1
fi

echo "Generated object files:"
for file in $OBJECT_FILES; do
    echo "  $file"
done

# 3. Link with GCC / MinGW
# ------------------------------------------------------------
echo ""
echo " Linking with GCC..."

"$GCC" \
    $OBJECT_FILES \
    "-L$RAYLIB_PATH" \
    -lraylibdll \
    -luser32 \
    -lgdi32 \
    -lwinmm \
    -lshell32 \
    -ladvapi32 \
    -lole32 \
    -loleaut32 \
    -luuid \
    -lcomdlg32 \
    -limm32 \
    -lversion \
    -o "$OUTPUT_FILE"
# ------------------------------------------------------------
# 4. Deploy raylib.dll
# ------------------------------------------------------------

OUTPUT_DIRECTORY="$(dirname "$OUTPUT_FILE")"
DLL_OUTPUT="$OUTPUT_DIRECTORY/raylib.dll"

cp -f "$RAYLIB_DLL" "$DLL_OUTPUT"

# ------------------------------------------------------------
# 5. Report
# ------------------------------------------------------------

echo
echo "============================================"
echo " Build successful"
echo "============================================"
echo " Linker: GCC"
echo " EXE:    $OUTPUT_FILE"
echo " DLL:    $DLL_OUTPUT"
