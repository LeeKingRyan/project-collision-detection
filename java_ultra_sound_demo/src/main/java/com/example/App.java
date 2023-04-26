package com.example;

import org.atsign.client.api.AtClient;
import org.atsign.common.AtException;
import org.atsign.common.AtSign;
import org.atsign.common.KeyBuilders;
import org.atsign.common.Keys.SharedKey;
/**
 * Hello world!
 *
 */
public class App 
{
    public static void main( String[] args ) throws Exception
    {
        AtSign java = new AtSign("@impossible6891");
        AtSign esp32 = new AtSign("@6isolated69");
        AtClient atClient = AtClient.withRemoteSecondary("root.atsign.org:64", java);

        //SharedKey sharedKey = new KeyBuilders.SharedKeyBuilder(java, esp32).key("initialization").build();
    

        SharedKey sharedKey = new KeyBuilders.SharedKeyBuilder(esp32, java).key("test").build();
        //SharedKey sharedKey = new KeyBuilders.SharedKeyBuilder(java, esp32).key("test").build();

        //String value = "butt stuff";

        //String ret = atClient.put(sharedKey, value).get();
        //System.out.println(ret);

        // Have a while loop that searches whetehr we get a signal,
        // or sting in which an object is detected in proximity, so we can
        // enter an while loop that reads distances. 
        
        String data = atClient.get(sharedKey).get();
        System.out.println("Data: " + data);

        /*
         * while(true) {
            String data = atClient.get(sharedKey).get();
            System.out.println("Data: " + data);
        }
        */
    }
}
