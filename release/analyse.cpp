//
//  main.cpp
//  AnalyzeIMK
//
//  Created by Ian Kennedy on 1/30/18.
//  Copyright © 2018 Ian Kennedy. All rights reserved.
//

#include <iostream>
#include <cmath>

int main(int argc, const char * argv[])
{
    const int startStdDev = 10;  // Zero based index, first sample used for std deviation calculation. Skip first 5 measurements to let system settle down.
    const int endStdDev = 20;   // Zero based index, last sample used for std deviation calculation
    const int neededSteps = 5; // Number of continous samples over the threshold needed to determine a hit
    const double x=2.23;        // 95% confidence interval for t distribution
    const int nsamps = 4;       // Number of channels
    int ndataPoints = 0; // Read from stdin
    int delTime = -1;    // Read from stdin
    double data [150] [4];
    double diffInit [4];
    double myAvg;
    double summ;
    double sum2;
    int bar[3][3];   // stores counts for green, yellow and red bars for each channel
    std::string message;
    const double diffFlat = 2.0; // Necessary multiple of sample compared to control to turn bar red if curve is flat
    
    /*
     * All input is given via stdin
     *
     * First the time between samples, in seconds, is given.
     * Then the number of data points (which is capped to 150, due to the size of data.
     * Then 4 x data points of data points
     */
    
    std::cin >> delTime;
    std::cin >> ndataPoints;
    
    
    // Initialize the counter for the bars (i=channel; j=green/yellow/red)
    for (int i=0; i<nsamps-1; i++)
    {
        for (int j=0; j<3; j++)
        {
            bar [i][j] = ndataPoints;
        }
    }
    
    if (ndataPoints > 150) // Ensure that all fits into data
        ndataPoints = 150;
    for (int j=0; j<ndataPoints; j++)
    {
        for (int k=0; k<4; k++)
        {
            std::cin >> data [j][k];
        }
    }
    
    // This section needs the first 20 data points to work out spread in the data, channel to channel, and to get first and second moments of the statistics for use later with incoming data.
    //    int index = startStdDev;
    // Get initial average differences (A-D), (B-D) etc. A, B, C are first three data samples, D is the negative control we use for comparison. Requires storage of the initial data for analysis prior to looking at real time incoming data from samples and control.
    // Wait until we have more than endStdDev data points. If not we skip the entire computation.
    if (ndataPoints>endStdDev)
    {
        double x0 = data[startStdDev][nsamps-1]/data[startStdDev][0]; // Get scaling factors to make all channels equal to control at step startStdDev
        double x1 = data[startStdDev][nsamps-1]/data[startStdDev][1];
        double x2 = data[startStdDev][nsamps-1]/data[startStdDev][2];
        for (int i=0;i<ndataPoints;  i++)
        {
            data[i][0] = data[i][0]*x0;  // Normalize all the data to the control at step startStdDev
            data[i][1] = data[i][1]*x1;
            data[i][2] = data[i][2]*x2;
        }
        
        for (int j=0; j<nsamps-1; j++)
        {
            sum2=0.0;
            for (int i=startStdDev; i<endStdDev; i++)
            {
                sum2 += std::abs(data [i][j])-(data [i][nsamps-1]);
            }
            diffInit [j] = sum2/(endStdDev-startStdDev);
            std::cerr << "diffInit  " << j << "  "<< diffInit [j] << std::endl;
        }
        
        
        // Begin by checking the integrity of the incoming data for the first 10 to 20 points, to make the spread in data is not excessive
        //   double sumsq=0.0;
        summ =0.0;
        myAvg=0.0;
        for (int j=0; j<nsamps; j++)
        {
            for (int i=startStdDev; i<endStdDev; i++)
            {
                summ += data [i][j];    //get the average of all the data, all wells, for the first 11 measurements
            }
        }
        myAvg=summ/nsamps/(endStdDev-startStdDev);
        std::cerr << "Average of all channels is " << myAvg << std::endl;
        
        summ=0.0;
        for (int j=0; j<nsamps; j++)
        {
            for (int i=startStdDev; i<endStdDev; i++)
            {
                summ += pow((data [i][j] - myAvg), 2) ;  //get the variance of all the data, all wells, for the first 11 measurements
            }
        }
        double stdDev=sqrt(summ/nsamps/(endStdDev-startStdDev));
        
        std::cerr << "Standard deviation for all data is " ;
        
        std::cerr << stdDev << "   "  << std::endl;
        
        
        if ((stdDev/myAvg) > 0.2)     // Check to see if the data from each channel has too much variance. If so, issue a warning.
            std::cerr << "Initial data from different channels have excessive spread: re do the test" << std::endl;
        
        //    Get standard deviations of samples compared to the control
        double sumsq=0.0;
        for (int j=0; j < nsamps-1; j++)
        {
            for(int i = startStdDev; i <endStdDev; i++) // average over the 10th to 20th data points to get initial differences. Delayed to the 10th data point to allow transients etc to settle down.
            {
                sumsq += pow((data [i][j] - data [i][nsamps-1]),2);   // Get mean square difference between all samples and the control for measurements byween startStdDev to endStdDev
            }
        }
        
        double avgDiff=sqrt(sumsq/(endStdDev-startStdDev)/(nsamps-1)) ;   //Standard deviation of samples compared to control at the beginning (10 to 20)
        std::cerr << "Average = " << myAvg << "   SD =  " << avgDiff << std::endl;
        
        /****** End of initial statistics section. Now for real time data coming in. ********/
        
        /***** Determining if test is successful or not *****/
        for (int i=0; i<nsamps; i++) // Looping through the existing data file for 3 samples compared to control. Needs to be done for real time data with 3 samples and the control. The samples are triplicate repeats of the same test. Remove from final product.
        {
            int index = endStdDev;
            bool thresholdExceeded = false; // Set to true when value exceeds x*stdDev the first time
            double firstValue = 0.0;        // First value above the threshold
            int counter = 0;                // Number of samples over the threshold
            int initTime = 0;                // Initial time threshold crossed for a positive test
            int done=0; // Used in the testing of existing file to prevent repeated print out of Positive result statement. Remove from final product.
            int firstTime = 0;              // Used to store first time slope goes positive in sample data
            while (index < ndataPoints-1)
            {
                double value = data[index][i] - data[index][nsamps-1];
                if (value > x*avgDiff) // Value over threshold
                {
                    if (!thresholdExceeded) // First time
                    {
                        thresholdExceeded = true;
                        firstValue = value; // Used later to make sure the signal does not go down again
                        initTime = index;   // Record the time when we first get a confirmed positive result. Not in original C++ code.
                    }
                    
                    ++ counter;
                    
                    if (counter >= neededSteps) // Enough steps found
                    {
                        if (value < 0.75*firstValue)
                        {
                            //      return WarningDecreasedDifference;
                            std::cerr << "Warning: Difference has decreased for sample " << (i+1) << std::endl;  // Issue an error code 1
                            message = "Warning: Difference has decreased for sample " + std::to_string(i+1);
                        }
                        else
                            
                            if (done==0)
                            {
                                done=1;
                                bar[i][0] = index; // Note the data point when we get 95% certainty, switching to yellow from index to ndataPoints
                                bar[i][1]=ndataPoints;
                            }
                        //     return Passed;
                        //return EXIT_SUCCESS;
                    }
                }
                else // Below threshold
                {
                    thresholdExceeded = false;
                    counter = 1;
                    
                    if (initTime == 0)  // If the threshold is never crossed ie initTime remains zero, then the sample is clean and the green bar only is shown. Bar[0][0] was initialized to ndataPoints.
                    {
                        bar[i][1] = 0;
                        bar[i][2] = 0;
                    }
                    if (value < 0.0)
                    {
                        // res = WarningControlGreaterThanSample;
                        std::cerr << "Warning: Sample is less than the control for sample " << (i+1) << std::endl;  // Issue error code 2
                        message = "Warning: Sample is less than the control for sample " + std::to_string(i+1);
                    }
                }
                
                ++ index;
            }
            /****** Test existing data file for an increase in the signal for each sample. This is 100% confirmation of a positive and leads to a red bar on screen.***/
            // Also test for a zero slope at a high signal, also indicative of a positive result
            int doneSlope = 0; // reset flag
            counter = 0; // Reset counter to check number of positive slope measurements
            bar[i][2]=0; // Initialize red bar to zero
            for (int j=endStdDev+3; j<ndataPoints-1; j++)
            {
                double slope = (data[j][i]-data[j-2][i])/data[j-1][i]; // j is data point, i is sample channel
                if ((slope >= 0.0) && (data[j][i] > diffFlat*data[j][nsamps-1])) // Check slope is positive and we are diffFlat times the control
                {
                    ++ counter;
                    if ((counter == 5) && (doneSlope == 0))  // Make sure the positive slope persists for at least 5 occurrences at the first time. // Make sure the positive slope persists for at least 5 occurrences.
                    {
                        firstTime = j-5;
                        bar[i][1]=firstTime;
                        bar[i][2]=ndataPoints;
                        doneSlope = 1;
                    }
                }
                
                else
                    counter = 0;
            }
            
        }
    }
    
    /*
     * The output to stderr is passed through and can be used for debugging (see output from host program).
     *
     * The stdout output must be formatted according to the table below.
     * Notice that the spacing must be one space exactly.
     *
     * The result lines are formatted as:
     *
     * <channel> <green> <yellow> <red> <result>
     *
     * channel = A, B or C
     * green/yellow/red = how many samples of each colour, from the left. These are stacked, so if green > red, red will not be visible, and so on.
     * result = result string shown to the right of the bar
     *
     * The output must end with a line reading "end".
     */
    
    //std::string message = "Hello World!";
    //std::string message = message;
    std::cout << "message" << std::endl;                                                // header for message
    std::cout << message << std::endl;                                                  // message on one line
    
    std::cout << "A " << bar[0][0] << " " << bar[0][1] << " " << bar[0][2] << " " << "x" << std::endl;    // result for channel A (40 steps green, 20 steps yellow, 20 steps red)
    std::cout << "B " <<  bar[1][0] << " " << bar[1][1] << " " << bar[1][2] << " " << "x" << std::endl;     // result for channel B (40 steps green, 40 steps yellow, no red)
    std::cout << "C " <<  bar[2][0] << " " << bar[2][1] << " " << bar[2][2] << " " << "x" << std::endl;      // result for channel C (50 steps green, no yellow, no red)
    std::cout << "end" << std::endl;                                                    // end marker
    
    return EXIT_SUCCESS;
}

