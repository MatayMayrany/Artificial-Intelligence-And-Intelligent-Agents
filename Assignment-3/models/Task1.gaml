/***
* Name: Assignment3 Task1
* Author: Matay Mayrany
* Description: Group 36, N queens problem
***/

model Task1

global {
    int N <- 8; 
    
    init {
        create Queen number: N {
           location <- {-10, -10};
        }
        
    }
    list<Queen> queens;
    list<ChessboardCell> ChessboardCells;
    
}

grid ChessboardCell skills:[fipa] width:N height:N neighbors:N {
   rgb color <- #white;
   bool busy <- false;
   init {
   		if ((grid_x + grid_y) mod 2 = 1) {
			color <- #black;
		} else {
			color <- #white;
		}
		add self to: ChessboardCells;
   }
 
}

species Queen skills:[fipa] {
    int myIndex;
    int currentRow <- 0;
    ChessboardCell selectedCell <-  nil;
    bool noPositionsAvailable <- false;
    bool foundMyPosition <- false;
    bool tryToFindPosition <- false;
    
    init {
    	queens << self;
    	myIndex <- length(queens) - 1;
    	if (length(queens) = N) {
    		do start_conversation with:(to: list(queens[0]), protocol: 'fipa-request', performative: 'inform', contents: ['FindYourPosition']);        
        	write "Let's get started!!!!";
    	}
    }
    
	reflex tellPerviousQueenToMove when: noPositionsAvailable {
        do start_conversation with:(to: list(queens[myIndex - 1]), protocol: 'fipa-request', performative: 'inform', contents: ['RePosition']);
        write name + ": " + queens[myIndex -1] + ", I can't find a spot can you please move";
        noPositionsAvailable <- false;
	}
     
	reflex informfoundMyPosition when: foundMyPosition {
         if(myIndex != N -1) {
             write name + ": I found a position, informing next queen of her turn!";
             do start_conversation with:(to: list(queens[myIndex +1]), protocol: 'fipa-request', performative: 'inform', contents: ['FindYourPosition']);
         } else {
             write "All positions found!";
         }
         foundMyPosition <- false;
        
    }
    
   reflex reactToMessages when: !empty(informs) {
    	message msg <- informs[0];
    	if(msg.contents[0] = 'FindYourPosition') {
    		tryToFindPosition <- true;
    		write name + ": I'm looking for a new position, currently at this row -> " + currentRow;
    	} else if (msg.contents[0] = 'RePosition') {
    		currentRow <- (currentRow + 1) mod N;
    		foundMyPosition <- false;
    		selectedCell.busy <- false;
    		selectedCell <- nil; 
    		location <- {-10, -10};
    		
    		if (currentRow = 0) {
    			noPositionsAvailable <- true;
    		} else {
    			tryToFindPosition <- true;
    		}
    	}
        informs <- nil;
    }
     
    reflex tryToFindPosition when: tryToFindPosition{
    	bool rowUnderAttack;
      	bool diganoalUnderAttack;
      
        loop i from: currentRow to: N - 1 {   
        	rowUnderAttack <- checkRowSafety(i);
        	diganoalUnderAttack <- checkDiagonal(i,myIndex);
        	if(!rowUnderAttack and !diganoalUnderAttack) {
        		// empty out current cell if this isn't the first time we are looking for one
        		if(selectedCell != nil) {
        			selectedCell.busy <- false;
        		}
        		currentRow <- i;
        		selectedCell <- ChessboardCells[getSelectedCell(myIndex, i)];
        		
        		location <- selectedCell.location;
        		selectedCell.busy <- true;
        		ChessboardCells[getSelectedCell(myIndex, currentRow)] <- selectedCell;
        		tryToFindPosition <- false;
        		foundMyPosition <- true;
        		break;
        	}
        	
        	if(i = (N-1) and !foundMyPosition) {
        		noPositionsAvailable <- true;
        		currentRow <- 0;
        		tryToFindPosition <- false;
        		foundMyPosition <- false;
        		location <- (point(-5,-5));
        		break;
        	}
        } 
        
     }
     
    int getSelectedCell(int curIndex, int row) {
    	return (N * row) + curIndex;
    }
     
	bool checkRowSafety(int row) {
     	int col <- myIndex -1;
     	if(col >= 0){	
     		loop while: col >= 0 {
        		ChessboardCell currentCell <- ChessboardCells[getSelectedCell(col,row)];
        		if(currentCell.busy = true) {
        			return true;
        		}
        		col <- col -1;
       		} 
     	}
     	
        return false;
    }
    
    bool checkDiagonal(int row, int col) {
    	int x <- col - 1;
    	int y <- row - 1;
    	loop while: (y >= 0 and x >= 0) {
    		ChessboardCell currentCell <- ChessboardCells[getSelectedCell(x, y)];
    		if(currentCell.busy = true) {
        		return true;
        	}
        	y <- y - 1;
     		x <- x - 1;
    	}
    	
    	x <- col + 1;
    	y <- row - 1;
    	loop while: (y < N and y >= 0 and x >= 0) {
    		ChessboardCell currentCell <- ChessboardCells[getSelectedCell(x, y)];
    		if(currentCell.busy = true) {
        		return true;
        	}
        	y <- y + 1;
     		x <- x - 1;
    	}
    	return false;
    }
     
    aspect default {
        draw pyramid(5) at: location color: #red;
    }
     
    
}

experiment main type: gui {
   
    output {
        display map type: opengl {
            grid ChessboardCell lines: #black ;
            species Queen;
        }
    }
}