TIMESTAMP=$(date +%Y%m%d%H%M%S)
./gradlew clean shadowJar

rm build/build-*.zip
mv build/libs/CvRenderer-1.0-SNAPSHOT-all.jar build/CvRenderer-"$TIMESTAMP".jar
#zip -j build/build-"$TIMESTAMP".zip build/libs/CvRenderer-1.0-SNAPSHOT.jar

terraform apply -input=false -var lambda-version="$TIMESTAMP"