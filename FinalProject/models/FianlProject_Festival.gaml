/***
* Name: FestivalPersonalities
* Author: mataymayrany
* Description: 
* 1. Create 5 different types of Agents with 50 instances
* 2. The agents have 1 set of rules to interact with other types.
* 3. 3 personal traits in the agents affect these rules
* 4. at least 2 different places where the guests can meet
* 5. Communication with fipa and continous simulation
* 6. Use gama montiors to track 1 interesting value
* 7. display 1 graph from that data
* 8. draw a conclusion for the created simulation
* Tags: Tag1, Tag2, TagN
***/

model FestivalPersonalities

global {
    list<point> stagePositions <- [{15, 15}, {85, 15}, {15, 85},{85, 85}];
    list<point> barPositions <- [{50, 40}, {50, 60}];
    list<rgb> stageColors <- [#blue, #purple, #magenta, #red];
    list<int> stagePercentages <- [100, 75, 25, 0];
    list<string> styles <- ["rap", "R&B", "DanceHall", "pop"];
    list<string> menu <- ["beer", "wine", "shots", "cocktails"];
	list<int> prices <- [10, 20, 30, 40];
   
    init {
        int counter <- 0;
        create Stage number: 4 {
            location <- stagePositions[counter];
            color <- stageColors[counter];
            rapPercentage <- stagePercentages[counter];
            popPercentage <- 100 - stagePercentages[counter];
            style <- styles[counter];
            counter <- counter + 1;
        }
        
        counter <- 0;	        
        create Bar number: 2 {
        	location <- barPositions[counter];
        	counter <- counter + 1;
        }
        
        create SocialGuest number: 2 {
        	location <- {rnd(100), rnd(100)};
        }
        
        create PopFan number: 30 {
        	location <- {rnd(100), rnd(100)};
        }  
        
        create HipHopFan number: 30 {
        	location <- {rnd(100), rnd(100)};
        }  
        
        create BoredGuest number: 2 {
        	location <- {rnd(100), rnd(100)};
        } 
        
        create BigSpender number: 2 {
        	location <- {rnd(100), rnd(100)};
        }        
    }
    //metrics
    int totalMoneySpentInBars <- 0;
    int totalNumberOfFriendshipsCreated <- 0; 
   
}

species Bar {
	bool is_bar <- true;
	aspect default {
        draw cube(8) at: location color: #violet;
    }
}
 
species Stage skills:[fipa]  {
	bool is_stage <- true;
	list<float> myValues <- [];
	int rapPercentage;
	int popPercentage;
	string style;
	rgb color;
	
	init {
		loop times: 6 {
			myValues << rnd(100.0)/10.0;
		}
	}
	
	reflex reAssignValues when: time mod 30 = 0 {
		myValues <- [];
		loop times: 6 {
			myValues << rnd(100.0)/10.0;
		}
	}
	
	reflex sendValues when: !empty(informs) {
		write name + ": Guests are asking for my values so I'm sending them!";
		Guest sender;
		loop msg over: informs {
			sender <- msg.sender;
			do inform with:(message: msg, contents: [myValues]);
		}
		informs <- [];
	}

    aspect default {
        draw cube(8) at: location color: color;
    }

 
}
 
species Guest skills:[moving, fipa] {
    list<float> myValues <- [];
    float mySpeed <- 0.0;
    point target <- nil;
    bool valuesChanged <- false;
    list<list<float>> stageValues <- [];
    list<float> utilityPerStage <- [0.0, 0.0, 0.0, 0.0];
    rgb color <- nil;
    bool isHipHopFan <- false;
    bool isPopFan <- false;
    bool isBored <- false;
    bool isSocial <- false;
    bool isBigSpender <- false;
    list<Guest> friends <- [];
    bool targetIsBar <- false;
    bool targetIsStage <- false;
    int targetStageIndex;
    bool goDrink <- false;
   	int crowdBelonging <- 1;
    
    init {
		loop times: 6 {
			myValues << rnd(100.0)/10.0;
		}
		
		mySpeed <- rnd(3.0, 6.0);
    }
    
    reflex moveToBar when: targetIsBar and goDrink {
    	target <- barPositions[rnd(0, 1)];
    }
   
    reflex moveToTarget when: target != nil {
        do goto target:{target.x - rnd(-10, 10), target.y - rnd(-10, 10)} speed: mySpeed;		
    }
    
    //request stage values every interval which is determined by the amount of friendsships and crowdbelonging agent attributes
    reflex getStageInformation when: time mod 50*crowdBelonging = 0  {
    	stageValues <- [];
    	crowdBelonging <- 1;
        do start_conversation with:(to: list(Stage), protocol: 'fipa-request', performative: 'inform', contents: ['Send Values']);
        write name + ": I want to know the stage attribute values!";       
     }
     
     reflex findTheMostAppropriateStage when: valuesChanged {
        valuesChanged <- false;
        utilityPerStage <- [0.0, 0.0, 0.0, 0.0];
        loop stageIndex from: 0 to: length(Stage) - 1 {
            loop valueIndex from: 0 to: length(stageValues) - 1 {
                list<float> currentStageValues <- stageValues[stageIndex];
                utilityPerStage[stageIndex] <- utilityPerStage[stageIndex] + (currentStageValues[valueIndex] * myValues[valueIndex]);
            }
        }
       
       	// choose max utility
        float maxValue <- max(utilityPerStage);
        int maxIndex <- 0;       
        loop currentUtilityIndex from:0 to: length(utilityPerStage) - 1 {
        	if(maxValue = utilityPerStage[currentUtilityIndex]) {
        		maxIndex <- currentUtilityIndex;
        	}
        }
        write name + ": found my match! going there now.";
        target <- stagePositions[maxIndex];
        targetIsStage <- true;
        targetIsBar <- false;
        targetStageIndex <- maxIndex;
     }
     
     reflex recieveValues when: (!empty(informs)) {
     	loop msg over: informs {
            stageValues << msg.contents[0];
        }
        valuesChanged <- true;
        informs <- [];
     }
     
     point getTarget {
     	return target;
     }
     
     aspect default {
        draw pyramid(3) color: color;
        draw sphere(1) at:{location.x,location.y, location.z + 3} color: color;
    }
   
}

species HipHopFan parent: Guest {
	int hypeLevel <- rnd(100);
	int crowdBelonging <- 0;
	int outgoingness <- rnd(75);
	list<string> favoritActsInOrder <- ["rap", "R&B", "DanceHall", "pop"];
	int generosity <- rnd(50);
	bool myTurnToBuyDrinks <- false;
	bool hyped <- hypeLevel > 50;
	bool goDrink <- false;
	rgb color <- #blue; 
	bool myTurnToPay <- false;
	
	init {
		isHipHopFan <- true;
		loop times: 6 {
			myValues << rnd(100.0)/10.0;
		}
		mySpeed <- 5.0;
    }
    
    reflex judgeStage when: super.getTarget() != nil and location distance_to(super.getTarget()) < 5 and super.targetIsStage and !goDrink {
    	do start_conversation with:(to: list(HipHopFan), protocol: 'fipa-request', 
    			performative: 'request', contents: ['Are you at this stage?', super.targetStageIndex]
    		);
    	
    	ask Stage at_distance 4 {
	    	if(self.rapPercentage = 100 and myself.hypeLevel < 100) {
	    		write name + ": Love this music!";
	    		myself.hypeLevel <- myself.hypeLevel + 10;
	    	} else if (self.rapPercentage = 75 and myself.hypeLevel < 100) {
	    		write name + ": This music is ok!";
	    		myself.hypeLevel <- myself.hypeLevel + 5;
	    	} else if (self.rapPercentage = 50 and myself.hypeLevel > 0) {
	    		write name + ": meh...";
	    		myself.hypeLevel <- myself.hypeLevel - 5;
	    	} else {
	    		write name + ": I hate this music!";
	    		if (myself.hypeLevel > 0) {
    	    		myself.hypeLevel <- myself.hypeLevel - 10;			
	    		}
	    	}
   		}	
    }
    
    reflex answerRequests when: !empty(requests) {
    	loop msg over: requests {
    		if (msg.contents[0] = "Are you at this stage?" and super.targetStageIndex = msg.contents[1]) {
				do start_conversation with:(to: msg.sender, protocol: 'fipa-request', performative: 'agree', contents: ['yes, Im here']);
				crowdBelonging <- crowdBelonging + 2;
				if (!(super.friends contains msg.sender)) {
    				super.friends << msg.sender;
    				write "I found a friend!";
    			}  			
    		} else if (msg.contents[0] = "do you want a drink?" and hypeLevel < 50) {
    			do start_conversation with:(to: msg.sender, protocol: 'fipa-request', performative: 'agree', contents: ['I would love one!', 2]);
    			myTurnToPay <- false;
				super.goDrink <- true;
		    	super.targetIsBar <- true;
		    	color <- #violet;    			
    		} else if (msg.contents[0] = "do you wanna be friends?") {
    			//reciever merely recognizes the message and the senders add to the tally
    			//make sure to always check that the friends are not already in the lists
    			if (outgoingness > 50 and !(friends contains msg.sender)) {
    				write name + ": sure, let's be friends " + msg.sender;
    				friends << msg.sender;
    				do start_conversation with:(to: msg.sender, protocol: 'fipa-request', performative: 'agree', contents: ['yes lets be friends']);
    			}
    		}
        }
        requests <- [];
    }
    
    reflex findOtherHipHoppers when: !empty(agrees) {
    	loop msg over: agrees {
    		// if other hip hoppers are here they add each other
    		if (msg.contents[0] = "yes, Im here") {
    			if (!(super.friends contains msg.sender)) {
    				super.friends << msg.sender;
    				write "I found a friend!";
    				totalNumberOfFriendshipsCreated <- totalNumberOfFriendshipsCreated + 1;	
    			}
				crowdBelonging <- crowdBelonging + 2;  			
    		} 
        }
        agrees <- [];
    }
    
    
    reflex timeToGetDrunk when: hypeLevel < 20 {
    	super.goDrink <- true;
    	super.targetIsBar <- true;
    	myTurnToPay <- true;
    	color <- #violet;
    }
    
    reflex drink when: super.goDrink and super.target != nil and location distance_to(super.getTarget()) < 2 and super.targetIsBar {
    	if(myTurnToPay){
    		write name + ": can i have one" + menu[2];
    		totalMoneySpentInBars <- totalMoneySpentInBars + prices[2];
    	}
   		write name + ": Woo, that was nice!";
    	hypeLevel <- hypeLevel + 10;
    	super.goDrink <- false; 
    	super.targetIsBar <- false;
    	color <- #blue;
    }
    
    reflex naturalHypeDrop when: time mod 30 = 0 {
   		hypeLevel <- hypeLevel - 5;
   	}
   	
	
	aspect default {
		 draw pyramid(3) color: color;
        draw sphere(1) at:{location.x,location.y, location.z + 3} color: color;
	}
}

species PopFan parent: Guest {
	int hypeLevel <- rnd(100);
	int outgoingness <- rnd(75);
	int generosity <- rnd(50);
	list<string> favoritActsInOrder <- ["pop", "DanceHall", "R&B", "rap"];
	bool myTurnToPay <- false;
	rgb color <- #red;
	
	init {
		isPopFan <- true;
		loop times: 6 {
			myValues << rnd(100.0)/10.0;
		}
		mySpeed <- 4.0;
    }
	
	reflex judgeStage when: super.getTarget() != nil and location distance_to(super.getTarget()) < 5 and super.targetIsStage and !goDrink {
    	do start_conversation with:(to: list(PopFan), protocol: 'fipa-request', 
    			performative: 'request', contents: ['Are you at this stage?', super.targetStageIndex]
    		);
    	
    	ask Stage at_distance 4 {
	    	if(self.popPercentage = 100 and myself.hypeLevel < 100) {
	    		write name + ": Love this music! it's pure pop!";
	    		myself.hypeLevel <- myself.hypeLevel + 10;
	    	} else if (self.popPercentage = 75 and myself.hypeLevel < 100) {
	    		write name + ": This music is ok! it's kinda poppy!";
	    		myself.hypeLevel <- myself.hypeLevel + 5;
	    	} else if (self.popPercentage = 50 and myself.hypeLevel > 0) {
	    		write name + ": meh... This isn't pop!";
	    		myself.hypeLevel <- myself.hypeLevel - 5;
	    	} else {
	    		write name + ": I hate this music! not pop at all";
    	    	myself.hypeLevel <- myself.hypeLevel - 10;			
	    	}
   		}	
    }
    
    reflex answerRequests when: !empty(requests) {
    	loop msg over: requests {
    		if (msg.contents[0] = "Are you at this stage?" and super.targetStageIndex = msg.contents[1]) {
				do start_conversation with:(to: msg.sender, protocol: 'fipa-request', performative: 'agree', contents: ['yes, Im here']);
				crowdBelonging <- crowdBelonging + 2;				
				if (!(friends contains msg.sender)) {
    				friends << msg.sender;
    				write "I found a friend!";
    			}  			
    		} else if (msg.contents[0] = "do you want a drink?") {
    			do start_conversation with:(to: msg.sender, protocol: 'fipa-request', performative: 'agree', contents: ['I would love one!', 1]);
    			myTurnToPay <- false;
    		} else if (msg.contents[0] = "do you wanna be friends") {
    			friends << msg.sender;
				do start_conversation with:(to: msg.sender, protocol: 'fipa-request', performative: 'agree', contents: ['yes lets be friends']);
    			write "I found a friend!";
    		}
        }
        requests <- [];
    }
    
    reflex findOtherPoppers when: !empty(agrees) {
    	loop msg over: agrees {
    		// if other poppers are here they add each other
    		if (msg.contents[0] = "yes, Im here") {
    			if (!(friends contains msg.sender)) {
    				friends << msg.sender;
    				write "I found a friend!";
    				totalNumberOfFriendshipsCreated <- totalNumberOfFriendshipsCreated + 1;	
    			}
				crowdBelonging <- crowdBelonging + 2;  			
    		} 
        }
        agrees <- [];
    }
    
    reflex timeToGetDrunk when: hypeLevel < 20 {
    	super.goDrink <- true;
    	super.targetIsBar <- true;
    	myTurnToPay <- true;
    	color <- #violet;
    }
    
    reflex drink when: super.goDrink and super.target != nil and location distance_to(super.getTarget()) < 2 and super.targetIsBar {
    	if(myTurnToPay){
    		write name + ": can i have one" + menu[2];
    		totalMoneySpentInBars <- totalMoneySpentInBars + prices[2];
    		write name + ": Woo, that was nice!";
    	} else {
    		write name + ": Woo, that was nice! Thanks bigSpender!";
    	}
    	hypeLevel <- hypeLevel + 10;
    	super.goDrink <- false; 
    	super.targetIsBar <- false;
    	myTurnToPay <- false;
    	color <- #red;
    }
    
    reflex naturalHypeDrop when: time mod 30 = 0 {
   		hypeLevel <- hypeLevel - 5;
   	}
    
	aspect default {
		draw pyramid(3) color: color;
        draw sphere(1) at:{location.x,location.y, location.z + 3} color: color;
	}
}

//Make the social guest start by sending everyone a friend request, 
//that is all they need to do and then the stage hop and increase their groud belonging based on vibes
species SocialGuest parent: Guest {
	int hypeLevel <- rnd(100);
	int outgoingness <- rnd(75, 100);
	int generosity <- rnd(50);
	list<string> favoritActsInOrder;
	int maximumFriendTrials <- 5;
	bool myTurnToPay <- false;
	rgb color <- #orange;
	
	init {
		isSocial <- true;
		loop times: 6 {
			myValues << rnd(100.0)/10.0;
		}
		mySpeed <- 6.0;
    }
    
    reflex tryToMakeFriends when: time mod (50 * outgoingness) = 0 and maximumFriendTrials > 0 {
    	do start_conversation with:(to: list(HipHopFan), protocol: 'fipa-request', 
    			performative: 'request', contents: ['do you wanna be friends?']
    		);
    	do start_conversation with:(to: list(PopFan), protocol: 'fipa-request', 
    			performative: 'request', contents: ['do you wanna be friends?']
    		);
    	do start_conversation with:(to: list(BigSpender), protocol: 'fipa-request', 
    			performative: 'request', contents: ['do you wanna be friends?']
    		);
    	do start_conversation with:(to: list(BoredGuest), protocol: 'fipa-request', 
    			performative: 'request', contents: ['do you wanna be friends?']
    		);
    }
    
    reflex listenToRequestAnswers when: !empty(agrees) {
    	loop msg over: agrees {
    		if (msg.contents[0] = "yes lets be friends") {
				write name + ": I found a friend!";
				if (!(friends contains msg.sender)){
					totalNumberOfFriendshipsCreated <- totalNumberOfFriendshipsCreated + 1;    			
					friends << msg.sender;				
				}
    		}
    	}
    	agrees <- [];
    }
    
    reflex readRequests when: !empty(requests) {
    	loop msg over: requests {
    		if (msg.contents[0] = "do you want a drink?") {
    			if (hypeLevel < 50) {
    				write name + ": sure I would love one";
    				do start_conversation with:(to: msg.sender, protocol: 'fipa-request', performative: 'agree', contents: ['I would love one!', 1]);
	    			myTurnToPay <- false;
					super.goDrink <- true;
			    	super.targetIsBar <- true;
			    	color <- #violet;
    				
    			}
    		}
    	}
    }
    
    reflex timeToGetDrunk when: hypeLevel < 20 {
    	super.goDrink <- true;
    	super.targetIsBar <- true;
    	myTurnToPay <- true;
    	color <- #violet;
    }
    
    reflex drink when: super.goDrink and super.target != nil and location distance_to(super.getTarget()) < 2 and super.targetIsBar {
    	if(myTurnToPay){
    		write name + ": can i have one" + menu[1];
    		totalMoneySpentInBars <- totalMoneySpentInBars + prices[1];
    	}
   		write name + ": Woo, that was nice!";
    	hypeLevel <- hypeLevel + 10;
    	super.goDrink <- false; 
    	super.targetIsBar <- false;
    	color <- #orange;
    }
    
    reflex naturalHypeDrop when: time mod 30 = 0 {
   		hypeLevel <- hypeLevel - 5;
   	}
    	
	aspect default {
		draw pyramid(3) color: color;
        draw sphere(1) at:{location.x,location.y, location.z + 3} color: color;
	}
	
}

species BigSpender parent: Guest {
	int hypeLevel <- rnd(100);
	int outgoingness <- rnd(50, 75);
	int generosity <- rnd(75, 100);
	list<string> favoritActsInOrder;
	bool askedFriendToGetADrink <- false;
	list<int> drinksToBuy <- [3];
	rgb color <- #green;
	
	init {
		isBigSpender <- true;
		loop times: 6 {
			myValues << rnd(100.0)/10.0;
		}
		mySpeed <- 4.0;
    }
    
    //try to get the bored people drunk by getting them in the friend group
    reflex getTheBoredPeopleDrunk when: (outgoingness > 55 and length(friends) < 5)  or outgoingness > 70 {
  		do start_conversation with:(to: list(BoredGuest), protocol: 'fipa-request', performative: 'request', contents: ['do you wanna be friends?']);
    }
 	
 	reflex readRequests when: !empty(requests) {
 		loop msg over: requests {
 			if(msg.contents[0] = "do you wanna be friends?") {
 				if (outgoingness > 50) {
 					if(!(friends contains msg.sender)) {
 						write name + ": I found a friend!";
 						friends << msg.sender;
 					}
 					
 				}
 			}
 		}
 	}
    
    reflex askIfFriendWantsADrink when: hypeLevel < 50 {
     	if(!empty(friends)) {
     		do start_conversation with:(to: [friends[0]], protocol: 'fipa-request', performative: 'request', contents: ['do you want a drink?']);
     	}
    }
    
    reflex readResponses when: !empty(agrees) {
    	loop msg over: agrees {
    		if (msg.contents[0] = "I would love one!" and !goDrink) {
    			drinksToBuy <<  msg.contents[1];
    			goDrink <- true;
    			targetIsBar <- true;
    			Guest temp <- friends[0];
    			friends[0] <- friends[length(friends) - 1];
    			friends[length(friends) - 1] <- temp;
    		} else if (msg.contents[0] = "yes lets be friends") {
    			if(!(friends contains msg.sender)) {
 						write name + ": I found a boring friend!";
 						friends << msg.sender;
 						totalNumberOfFriendshipsCreated <- totalNumberOfFriendshipsCreated + 1;
 				}
    		}
    	}
    }
    
    reflex goDrink when: hypeLevel < 40 and !targetIsBar and !goDrink {
    	super.goDrink <- true; 
    	super.targetIsBar <- true;
    	color <-  #violet;
    }
    
    
    reflex buyDrinks when: super.goDrink and super.target != nil and location distance_to(super.getTarget()) < 4 and super.targetIsBar {
    	loop i over: drinksToBuy {
    		write name + ": can I get " + menu[i];
    		totalMoneySpentInBars <- totalMoneySpentInBars + prices[i];
    		write name + ": Woo, that was nice!";
    		hypeLevel <- hypeLevel + 10;
    		super.goDrink <- false; 
    		super.targetIsBar <- false;
    	} 
    	color <- #green;
    }
    
   	reflex naturalHypeDrop when: time mod 30 = 0 {
   		hypeLevel <- hypeLevel - 5;
   	}

    
	aspect default {
		draw pyramid(3) color: color;
        draw sphere(1) at:{location.x,location.y, location.z + 3} color: color;
	}
	
}

species BoredGuest parent: Guest {
	int hypeLevel <- rnd(25);
	int outgoingness <- rnd(25);
	int generosity <- rnd(50);
	list<string> favoritActsInOrder;
	rgb color <- #black;
	
	init {
		isBored <- true;
		loop times: 6 {
			myValues << rnd(100.0)/10.0;
		}
		mySpeed <- 2.0;
    }
    
    reflex execessiveHypeDrop when: time mod 10 = 0 {
    	hypeLevel <- hypeLevel - 10;
    }
    
    //basically barely do anything unless someone forces you but friendliness makes you gradually more excited
    reflex reactToMessages when: !(empty(requests)) {
    	loop msg over: requests {
    		if (msg.contents[0] = "do you wanna be friends?") {
    			if (outgoingness > 50 or (outgoingness > 25 and flip(0.5))) {
    				if (!(friends contains msg.sender)) {
	    				write name + ": sure, let's be friends.";					
    					friends << msg.sender;
    				}
    			}
    			outgoingness <- outgoingness + 5;
    		} else if (msg.contents[0] = "do you want a drink?") {
    			if (hypeLevel < 50 and outgoingness > 25) {
    				do start_conversation with:(to: msg.sender, protocol: 'fipa-request', performative: 'agree', contents: ['I would love one!', 2]);
					super.goDrink <- true;
			    	super.targetIsBar <- true;
			    	color <- #violet;
    			}
    		}
    	}
    	requests <- [];
    }
    
    reflex drink when: super.goDrink and super.target != nil and location distance_to(super.getTarget()) < 2 and super.targetIsBar {
   		write name + ": Woo, that was nice!";
    	hypeLevel <- hypeLevel + 10;
    	super.goDrink <- false; 
    	super.targetIsBar <- false;
    	color <- #orange;
    }
	
	aspect default {
		draw pyramid(3) color: color;
        draw sphere(1) at:{location.x,location.y, location.z + 3} color: color;
	}
	
}
 
 
experiment main type: gui
{   
    output {
    	
//    	display chartG{
//    		chart "Total ammount of money spent in bars " type: scatter{
//    			data "Money Spent" value: totalMoneySpentInBars;
//    		}
//    	}
    	
    	display chartG{
    		chart "Total ammount of friendships created " type: scatter{
    			data "Created Friendships" value: totalNumberOfFriendshipsCreated;
    		}
    	}
    	
        display map type: opengl {
            species Guest;
            species Stage;
            species SocialGuest;
            species PopFan;
            species HipHopFan;
            species BoredGuest;
            species BigSpender;
            species Bar;
        }
    }
}