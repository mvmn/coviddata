// https://api-covid19.rnbo.gov.ua/data?to=2020-01-22
// https://api-covid19.rnbo.gov.ua/data?to=2020-05-11

// https://raw.githubusercontent.com/CSSEGISandData/COVID-19/master/csse_covid_19_data/csse_covid_19_daily_reports/01-22-2020.csv
// https://raw.githubusercontent.com/CSSEGISandData/COVID-19/master/csse_covid_19_data/csse_covid_19_daily_reports/05-10-2020.csv
// =====
groovy.grape.Grape.grab([group: 'org.apache.commons', artifact: 'commons-csv', version: '1.8'])

dateFormatData = new java.text.SimpleDateFormat("yyyy-MM-dd");
dateFormatRnbo = new java.text.SimpleDateFormat("yyyy-MM-dd");
dateFormatJhu = new java.text.SimpleDateFormat("MM-dd-yyyy");

safe = { call, maxlines -> try{ call() }catch(Exception ex) { System.err.println(ex.getClass().canonicalName+": "+ex.message+"\n  "+ex.stackTrace.toList().subList(0, Math.min(maxlines, ex.stackTrace.size())).join("\n  ")) }};

folder = new File("/Users/mvmn/tmp/coviddata/")
folderRnbo = new File(folder, "rnbo");
if(!folderRnbo.exists()) { folderRnbo.mkdir(); }
folderJhu = new File(folder, "jhu");
if(!folderJhu.exists()) { folderJhu.mkdir(); }


fetch = {
c = Calendar.getInstance();
c.set(Calendar.YEAR, 2020);
c.set(Calendar.MONTH, 1);
c.set(Calendar.DAY_OF_MONTH, 22);
c.set(Calendar.HOUR_OF_DAY, 0);
c.set(Calendar.MINUTE, 0);
c.set(Calendar.SECOND, 0);
c.set(Calendar.MILLISECOND, 0);

now = new Date();
while(c.getTime().before(now)) {
dateStr = dateFormatData.format(c.time);
println dateStr;

urlRnbo = "https://api-covid19.rnbo.gov.ua/data?to=" + dateFormatRnbo.format(c.time);
urlJhu = "https://raw.githubusercontent.com/CSSEGISandData/COVID-19/master/csse_covid_19_data/csse_covid_19_daily_reports/"+dateFormatJhu.format(c.time)+".csv";

fileRnbo = new File(folderRnbo, dateStr+".json")
if(!fileRnbo.exists()) {
  println "GET "+urlRnbo;
  safe({ fileRnbo.text = new URL(urlRnbo).content.text; }, 5);
}
fileJhu = new File(folderJhu, dateStr+".csv")
if(!fileJhu.exists()) {
  println "GET "+urlJhu;
  safe({ fileJhu.text = new URL(urlJhu).content.text; }, 5);
}

c.add(Calendar.DAY_OF_MONTH, 1);
}
}

processRnboData = { fullRegen ->
dataRnboJsonFile = new File(folder, "data_rnbo.json");

folderJhu.listFiles().each{ csvFile -> fn = csvFile.absolutePath;fn=new File(fn.substring(0, fn.lastIndexOf('.'))+".json"); if(!fn.exists()) { csvFile.withReader{ r -> records = org.apache.commons.csv.CSVFormat.DEFAULT.withFirstRecordAsHeader().parse(r).records; asMaps = records.collect{ it.toMap() }; println "Writing file "+fn.name; fn.text = groovy.json.JsonOutput.prettyPrint(groovy.json.JsonOutput.toJson(asMaps)); } } }; 0

json = new groovy.json.JsonSlurper();
data = dataRnboJsonFile.exists()? json.parse(dataRnboJsonFile) : new TreeMap();

folderRnbo.listFiles().grep{ it.name.endsWith(".json") }.sort{ it.name }.each{ date = it.name.substring(0, it.name.indexOf('.')); if(fullRegen || data[date]==null) { println it.name; data[date]=[:]; json.parse(it).ukraine.each{ data[date][it.label.en]=[confirmed:it.confirmed, deaths:it.deaths, recovered:it.recovered, existing:it.existing, suspicions:it.suspicion, delta_confirmed:it.delta_confirmed, delta_deaths:it.delta_deaths, delta_recovered:it.delta_recovered, delta_existing:it.delta_existing, delta_suspicions:it.delta_suspicion] } } }; 0

dataRnboJsonFile.text = groovy.json.JsonOutput.prettyPrint(groovy.json.JsonOutput.toJson(data)); 0
}

fetch(); processRnboData(); 0
