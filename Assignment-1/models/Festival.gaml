///***
//* Name: Festival
//* Author: mataymayrany
//* Description: Simualating a festival with bars, restaurants 
//* and guests that find the directions to the stores via an information center
//***/
//
model Festival

global {
	init {
		
		seed <- 10.0;
		bool alternateFlag;
		
		create FestivalGuest number: 20 {
			location <- {rnd(100), rnd(100)};
		}
		
		create Store number: 6 {
			location <- {rnd(100), rnd(100)};
			// blue: bar, red: restaurant
			if(alternateFlag) {
				color <- #blue;
				bar <- true;
				restaurant <- false;
				alternateFlag <- false;
			} else {
				color <- #red; 
				bar <- false;
				restaurant <- true;
				alternateFlag <- true;
			}
		}
		
		create InformationCenter number: 1 {
			location <- {50, 50};
		}
		
		
	}
}

species Store {	
	bool bar <- false;
	bool restaurant <- false;
	rgb color <- #white;
	
	aspect default {
		draw cube(8) at: location color: color; 
	}
	
}

species InformationCenter {
	list<Store> restaurants <- nil;
	list<Store> bars <- nil;
	
	init {
		ask Store {
			if(self.bar) {
				myself.bars << self;
			} else if(self.restaurant) {
				myself.restaurants << self;
				write myself.restaurants;
			}
		}
	}
	
	aspect default {
		draw pyramid(15) at: location color: #black;
	}
}


species FestivalGuest skills: [moving] {
	
	int thirsty <- rnd(1000);
	int hungry <- rnd(1000);
	point informationCenterLocation <- {50, 50};
	rgb color <- nil;
	point targetPoint <- nil;
	Store targetStore <- nil;
	bool alternateFlag;
	
		
	reflex goToStore when: (targetStore != nil) {
		write 'going to Store';
		do goto target:targetStore;
		ask Store at_distance 2 {
			if (myself.thirsty >= 500) {
				myself.thirsty <- 0;
			} else {
				myself.hungry <- 0;
			}
		}
		
		if (thirsty < 500 and hungry < 500) {
			targetPoint <- nil;
			targetStore <- nil;
			color <- #green;
		}
	}
	
	
	reflex beIdle when: targetPoint = nil and thirsty < 500 and hungry < 500 {
		write 'being idle';
		color <- #green;
		do wander;
	}

	
	reflex goToInformationCenter when: (hungry >= 500 or thirsty >= 500) and targetStore = nil {
		write 'going to information center';
		do goto target:informationCenterLocation;
		ask InformationCenter at_distance 2 {			
			if (myself.thirsty >= 500) {
				int i <- rnd(length(self.restaurants) - 1);
				myself.targetStore <- self.restaurants[i];
				write myself.targetStore;
				myself.color <- #red;
			} else {
				int i <- rnd(length(self.bars) - 1);
				myself.targetStore <- self.bars[i];
				myself.color <- #blue;
			}
		}
	}


	reflex increaseValues when: thirsty < 500 or hungry < 500 {
		if (alternateFlag) {
			thirsty <- thirsty + 3;
			alternateFlag <- false;
		} else {
			hungry <- hungry + 3;
			alternateFlag <- true;
		}
	}
	
	aspect default {
		draw sphere(2) at: location color: color;
	}
	
}

experiment main type: gui {
	output {
		display map type: opengl 
		{
			species FestivalGuest;
			species Store;
			species InformationCenter;
		}
	}
}


