rm target/*/*.lua
cp src/main/lua/* target/APIServer/
cp src/main/lua/* src/example/lua/* src/test/lua/* target/test

cd target/test
for f in *.lua; do
  luamin -f $f > ../minified/$f
done

for f in *Test.lua; do
  echo "Testing $f...";
  lua $f
  #java -cp ../../../luaj-3.0.1/lib/luaj-jse-3.0.1.jar lua $f
done

cd ../minified
for f in *Test.lua; do
  echo "Testing $f...";
  lua $f
  #java -cp ../../../luaj-3.0.1/lib/luaj-jse-3.0.1.jar lua $f
done

