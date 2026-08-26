import shutil, os, sys

src = r"C:\Users\Ashkan\Claude\Projects\اپ اندروید"
dst = r"C:\TennisApp"

print("Syncing files to C:\\TennisApp ...")

# Copy lib/
lib_src = os.path.join(src, "lib")
lib_dst = os.path.join(dst, "lib")
if os.path.exists(lib_dst):
    shutil.rmtree(lib_dst)
shutil.copytree(lib_src, lib_dst)
print("  lib/ copied")

# Copy pubspec.yaml
shutil.copy2(os.path.join(src, "pubspec.yaml"), os.path.join(dst, "pubspec.yaml"))
print("  pubspec.yaml copied")

print("\nDone! Now run:")
print("  cd C:\\TennisApp")
print("  D:\\flutter\\bin\\flutter.bat pub get")
print("  D:\\flutter\\bin\\flutter.bat build apk --release")
