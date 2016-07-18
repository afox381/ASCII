//
//  ViewController.m
//  ASCII
//
//  Created by Andrew Fox on 16/10/2016.
//  Copyright © 2016 Explode Ltd. All rights reserved.
//

#import "ViewController.h"

#define kCellGridMaxX               20
#define kCellGridMaxY               10
#define kCellWidth                  18
#define kCellHeight                 18
#define kNextCellTimerSpeedMSecs    0.01
#define kCursorTimerSpeedMSecs      0.1
#define kTextViewWidthHeightRatio   1.8
#define kInputTextFontDeniminator   13.5
#define kGridLeadingTrailingBuffer  20
#define kRandomLinesCount           5

static NSString *const kCommandPacman					= @"pacman";
static NSString *const kCommandExplode					= @"explode";
static NSString *const kCommandAbout					= @"about";
static NSString *const kCommandClear					= @"clear";
static NSString *const kCommandHelp                     = @"help";
static NSString *const kCommandWelcome					= @"welcome";
static NSString *const kCommandRandom					= @"random";
static NSString *const kCommandTetris					= @"tetris";

@interface ViewController () <UITextViewDelegate>
{
    UILabel  *_cellLabel[kCellGridMaxX][kCellGridMaxY];
    NSString *_cellString[kCellGridMaxX][kCellGridMaxY];
}

@property (nonatomic, weak) IBOutlet UIImageView            *logoImageView;
@property (nonatomic, weak) IBOutlet UIView                 *gridContainerView;
@property (nonatomic, weak) IBOutlet UITextView             *inputTextView;

@property (nonatomic, weak) IBOutlet NSLayoutConstraint    *logoImageViewCentreConstraint;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint    *gridWidthConstraint;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint    *gridHeightConstraint;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint    *textViewHeightConstraint;

@property (nonatomic, strong) UIView    *cursorView;
@property (nonatomic, strong) NSTimer   *logoAnimationTimer;
@property (nonatomic, assign) CGPoint   currentCell;

@property (nonatomic, strong) NSString  *pacmanGridString;
@property (nonatomic, strong) NSString  *explodeGridString;
@property (nonatomic, strong) NSString  *aboutGridString;
@property (nonatomic, strong) NSString  *tetrisGridString;

@property (nonatomic, strong) NSString  *helloString;
@property (nonatomic, strong) NSString  *infoString;
@property (nonatomic, strong) NSString  *helpString;
@property (nonatomic, strong) NSString  *aboutString;

@property (nonatomic, assign) BOOL       initialLayoutComplete;

@end

@implementation ViewController

//***************************************************
// Synopsis:
//***************************************************
- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self setup];
}


//***************************************************
// Synopsis:
//***************************************************
- (void)viewDidLayoutSubviews
{
    if (!_initialLayoutComplete)
    {
        // do our layout code
        [self layoutGrid];
        [self layoutCursor];
        [self layoutTextView];
        _initialLayoutComplete = YES;
    }
}


//***************************************************
// Synopsis:
//***************************************************
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


//***************************************************
// Synopsis:
//***************************************************
- (void)setup
{
    _gridContainerView.alpha = 0.0;
    _inputTextView.alpha = 0.0;
    _inputTextView.tintColor = [UIColor colorWithRed:0.0 green:1.0 blue:0.0 alpha:1.0];
    
    [self setupStrings];
    
    // we're ready too go, so animate the logo and prepare for input
    [self animateLogo];
}


//***************************************************
// Synopsis:
//***************************************************
- (void)setupStrings
{
    _pacmanGridString = @"####################"\
                        @"#.......####.......#"\
                        @"#.###.#......#.###.#"\
                        @"#.#...#.#AA#.#...#.#"\
                        @"....###.#AA#.###...."\
                        @"#.#.###.####.###.#.#"\
                        @"#.#...#..C...#...#.#"\
                        @"#.###.###.####.###.#"\
                        @"#..................#"\
                        @"############.©2016.#";
    
    _aboutGridString =  @"===================="\
                        @"                    "\
                        @"AAA  SS  CC III III "\
                        @"A A S   C    I   I  "\
                        @"A A SS  C    I   I  "\
                        @"AAA   S C    I   I  "\
                        @"A A SSS  CC III III "\
                        @"                    "\
                        @" By Andrew Fox ©2016"\
                        @"====================";
    
    _explodeGridString =@"     *        *     "\
                        @"     *       *      "\
                        @"###   *  #  *  #    "\
                        @"#        #    ## ## "\
                        @"## # ##### # # ##  #"\
                        @"#   # # ### ## #### "\
                        @"#### ##### #  ## ###"\
                        @"      #             "\
                        @"   *  #  *      *   "\
                        @"  *      * ©2016 ** ";
    _tetrisGridString = @"|                  |"\
                        @"+---+   +----------+"\
                        @"| . |   | . . . . .|"\
                        @"+ . '---+---+---+ .+"\
                        @"| . . . | . . . | .|"\
                        @"+ . +---+ . +---+--+"\
                        @"| . | . . . | . . .|"\
                        @"+---+---+---+ . +--+"\
                        @"| ©2016 | . . . |  |"\
                        @"+-------+---+---+--+";
    
    
    _infoString = @"Line coordinates should be entered in the form (x,y)–(x,y),(x,y)–(x,y),... (no spaces) where (x,y) are the coordinates of the ends of each line. Type \"help\" for more information.";
    _helpString = @"Line coordinates should be entered in the form (x,y)–(x,y),(x,y)–(x,y),... (no spaces) where (x,y) are the coordinates of the ends of each line. Any number of coordinates ranging from 0-19 in x, and 0-9 in y are acceptable.\n\"pacman\" - a blast from the past\n\"about\" - about ASCII\n\"random\" - show some random lines\n\"tetris\" - more fun\n\"clear\" - clear the screen";
    _helloString = [NSString stringWithFormat:@"Welcome to the ASCII line generator. %@", _infoString];
    _aboutString = @"ASCII is an ASCII line drawing app for the iPhone written by Andrew Fox, CoFounder of Explode Ltd, created for demo purposes.";
}


//***************************************************
// Synopsis:
//***************************************************
- (void)layoutGrid
{
    // setup an initial grid width based on our screen width
    _gridWidthConstraint.constant = self.view.frame.size.width - (kGridLeadingTrailingBuffer * 2);
    int cellWidthHeight = _gridWidthConstraint.constant / kCellGridMaxX;
    
    // setup labels for each of our ascii cells
    for (int y = 0; y < kCellGridMaxY; y++)
    {
        for (int x = 0; x < kCellGridMaxX; x++)
        {
            UILabel *cellLabel = [[UILabel alloc] initWithFrame:CGRectMake(x * cellWidthHeight, y * cellWidthHeight,cellWidthHeight,cellWidthHeight)];
            cellLabel.font = [UIFont fontWithName:@"Courier New" size:cellWidthHeight];
            cellLabel.textColor = [UIColor greenColor];
            cellLabel.backgroundColor = [UIColor colorWithRed:0.0 green:30.0/255.0 blue:0.0 alpha:1.0];
            cellLabel.textAlignment = NSTextAlignmentCenter;
            
            [_gridContainerView addSubview:cellLabel];
            _cellLabel[x][y] = cellLabel;
            
            _cellString[x][y] = @"";
        }
    }
    
    // refresh the grid width based on the cell width
    _gridWidthConstraint.constant = cellWidthHeight * kCellGridMaxX;
    _gridHeightConstraint.constant = cellWidthHeight * kCellGridMaxY;
}


//***************************************************
// Synopsis:
//***************************************************
- (void)layoutCursor
{
    int cellWidthHeight = _gridContainerView.frame.size.width / kCellGridMaxX;

    _cursorView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 2, cellWidthHeight)];
    _cursorView.backgroundColor = [UIColor greenColor];
    [_gridContainerView addSubview:_cursorView];
    
    [self animateCursor];
}


//***************************************************
// Synopsis:
//***************************************************
- (void)layoutTextView
{
    _textViewHeightConstraint.constant = _inputTextView.frame.size.width / kTextViewWidthHeightRatio;
    
    float fontSize = _textViewHeightConstraint.constant / kInputTextFontDeniminator;
    _inputTextView.font = [UIFont fontWithName:@"Courier New" size:fontSize];
}


//***************************************************
// Synopsis:
//***************************************************
- (void)prepareForInput
{
    _inputTextView.alpha = 1.0;
    [_inputTextView becomeFirstResponder];
    
    [self handleCommand:@"welcome"];
}


//***************************************************
// Synopsis:
//***************************************************
- (void)prepareCellStringsFromLineArray:(NSArray*)lineArray
{
    [self clearCellStrings];
    
    // go through each pair and add to our cellString grid
    for (NSArray *coordsArray in lineArray)
    {
        for (int i = 0; i < [coordsArray count]; i++)
        {
            CGPoint pt = [coordsArray[i] CGPointValue];
            _cellString[(int)pt.x][(int)pt.y] = @"X";
        }
    }
    
    [self refreshCells];
}


//***************************************************
// Synopsis:
//***************************************************
- (void)prepareCellStringsFromString:(NSString*)string
{
    if (string == nil || (string.length != kCellGridMaxX * kCellGridMaxY))
    {
        NSString *error = [NSString stringWithFormat:@"Error! Length %d should be %d", string.length, kCellGridMaxX * kCellGridMaxY];
        NSLog(error);
        return;
    }
    
    for (int y = 0; y < kCellGridMaxY; y++)
    {
        for (int x = 0; x < kCellGridMaxX; x++)
        {
            int charIndex = (y * kCellGridMaxX) + x;
            _cellString[x][y] = [string substringWithRange:NSMakeRange(charIndex, 1)];
        }
    }
    
    [self refreshCells];
}


//***************************************************
// Synopsis:
//***************************************************
- (NSString*)generateRandomLinesStringForCount:(NSUInteger)lineCount
{
    NSMutableString *coordsString = [NSMutableString new];
    for (int i = 0; i < lineCount; i++)
    {
        int coordX1 = rand() % kCellGridMaxX;
        int coordY1 = rand() % kCellGridMaxY;
        int coordX2 = rand() % kCellGridMaxX;
        int coordY2 = rand() % kCellGridMaxY;
        [coordsString appendFormat:@"(%d,%d)-(%d,%d)", coordX1, coordY1, coordX2, coordY2];
        if (i != (lineCount-1))
            [coordsString appendString:@","];
    }
    
    return [coordsString copy];
}


#pragma mark - cursor

//***************************************************
// Synopsis:
//***************************************************
- (void)setCursorLocation:(CGPoint)location
{
    CGRect frame = _cursorView.frame;
    frame.origin = location;
    _cursorView.frame = frame;
}


//***************************************************
// Synopsis: infinite animation loop for our cursor
//***************************************************
- (void)animateCursor
{
    float targetAlpha;
    if (_cursorView.alpha == 0.0)
        targetAlpha = 1.0;
    else
        targetAlpha = 0.0;
    
    // animate to visible or hidden in an infinite loop
    [UIView animateWithDuration:0.2 animations:^{
        _cursorView.alpha = targetAlpha;
    } completion:^(BOOL finished) {
        [self animateCursor];
    }];
}


#pragma mark - cells

//***************************************************
// Synopsis:
//***************************************************
- (void)refreshCells
{
    _cursorView.hidden = NO;
    _currentCell = CGPointZero;
    
    [self nextCell];
}


//***************************************************
// Synopsis:
//***************************************************
- (void)nextCell
{
    UILabel *currentCellLabel = _cellLabel[(int)_currentCell.x][(int)_currentCell.y];
    [self setCursorLocation:CGPointMake(currentCellLabel.frame.origin.x + kCellWidth, currentCellLabel.frame.origin.y)];
    currentCellLabel.text = _cellString[(int)_currentCell.x][(int)_currentCell.y];

    // and onto the next...
    _currentCell.x++;
    if (_currentCell.x == kCellGridMaxX)
    {
        _currentCell.x = 0;
        _currentCell.y++;
    }
    if (_currentCell.y == kCellGridMaxY)
    {
        // we've reached the end
        _cursorView.hidden = YES;
    }
    else
    {
        NSTimer *nextCellTimer = [NSTimer timerWithTimeInterval:kNextCellTimerSpeedMSecs target:self selector:@selector(nextCell) userInfo:nil repeats:NO];
        [[NSRunLoop mainRunLoop] addTimer:nextCellTimer forMode:NSRunLoopCommonModes];
    }
}


//***************************************************
// Synopsis:
//***************************************************
- (void)clearCellStrings
{
    for (int y = 0; y < kCellGridMaxY; y++)
    {
        for (int x = 0; x < kCellGridMaxX; x++)
        {
            _cellString[x][y] = @"";
        }
    }
}


#pragma mark - logo

//***************************************************
// Synopsis:
//***************************************************
- (void)animateLogo
{
    // we want to animate in the fashion of old computers, so we'll do it with a timer
    _logoAnimationTimer = [NSTimer timerWithTimeInterval:0.15 target:self selector:@selector(updateLogo) userInfo:nil repeats:YES];
    [[NSRunLoop mainRunLoop] addTimer:_logoAnimationTimer forMode:NSRunLoopCommonModes];
}


//***************************************************
// Synopsis:
//***************************************************
- (void)updateLogo
{
    _logoImageViewCentreConstraint.constant -= kCellWidth;
    
    // we're off-screen so kill the timer and carry on
    if (_logoImageViewCentreConstraint.constant < -_logoImageView.frame.size.width)
    {
        [_logoAnimationTimer invalidate];
        _logoAnimationTimer = nil;
        
        [self logoAnimationComplete];
    }
}


//***************************************************
// Synopsis:
//***************************************************
- (void)logoAnimationComplete
{
    // once the animation is complete we can show the grid, show a welcome page and turn on inpout
    [UIView animateWithDuration:0.3 animations:^{
        _gridContainerView.alpha = 1.0;
    } completion:^(BOOL finished) {
        
        [self prepareCellStringsFromString:_aboutGridString];
    }];
    
    [self prepareForInput];
}


#pragma mark - line methods

//***************************************************
// Synopsis:
//***************************************************
- (NSArray*)lineArrayForCoordString:(NSString*)coordString
{
    // get our coords groupings into something we can use
    NSString *delimitedCoords = [coordString stringByReplacingOccurrencesOfString:@"),(" withString:@") , ("];
    NSArray *coordPairsArray = [delimitedCoords componentsSeparatedByString:@" , "];
    NSMutableArray *returnArray = [NSMutableArray new];
    
    if (coordPairsArray == nil)
        return nil;
    
    // split the text into coordinate pairs, test format and add to our array if ok
    for (NSString *coordPair in coordPairsArray)
    {
        // regex allows "(0-19,0-9)" only, no spaces
        NSString *coordsRegex = @"(\\()([01]?\\d)(\\,)([0-9])(\\))(\\-)(\\()([01]?\\d)(\\,)([0-9])(\\))";
        NSPredicate *coordsTest = [NSPredicate predicateWithFormat:@"SELF MATCHES[c] %@", coordsRegex];
        
        if ([coordsTest evaluateWithObject:coordPair] == NO)
            return nil;
        else
        {
            NSString *coordPairNoHyphen = [coordPair stringByReplacingOccurrencesOfString:@"-" withString:@","]; // remove the hyphen
            NSCharacterSet* characterSet = [[NSCharacterSet characterSetWithCharactersInString:@"0123456789,"] invertedSet];
            NSString *commaDelimitedCoords = [[coordPairNoHyphen componentsSeparatedByCharactersInSet:characterSet] componentsJoinedByString:@""]; // remove brackets
            NSArray* arrayOfCoords = [commaDelimitedCoords componentsSeparatedByString:@","]; // split into an array
            
            CGPoint pt1 = CGPointMake([arrayOfCoords[0] floatValue], [arrayOfCoords[1] floatValue]);
            CGPoint pt2 = CGPointMake([arrayOfCoords[2] floatValue], [arrayOfCoords[3] floatValue]);
            
            NSArray *lineArray = [self bresenhamLineBetween:pt1 andCoord:pt2];
            [returnArray addObject:lineArray];
        }
    }
    
    return [returnArray copy];
}


//***************************************************
// Synopsis:	Bresenham's line drawing algorithm
//***************************************************
-(NSArray*)bresenhamLineBetween:(CGPoint)coord1 andCoord:(CGPoint)coord2
{
    int x1 = (int)coord1.x;
    int y1 = (int)coord1.y;
    int x2 = (int)coord2.x;
    int y2 = (int)coord2.y;

    int dy = y2 - y1;
    int dx = x2 - x1;
    int stepx, stepy;
    
    if (dy < 0) { dy = -dy;  stepy = -1; } else { stepy = 1; }
    if (dx < 0) { dx = -dx;  stepx = -1; } else { stepx = 1; }
    dy <<= 1;        // dy is now 2*dy
    dx <<= 1;        // dx is now 2*dx
    
    NSMutableArray *lineCoordsArray = [NSMutableArray new];
    CGPoint ptCoord = CGPointMake(x1,y1);
    [lineCoordsArray addObject:[NSValue valueWithCGPoint:ptCoord]];
    
    if (dx > dy)
    {
        int fraction = dy - (dx >> 1);  // same as 2*dy - dx
        while (x1 != x2)
        {
            if (fraction >= 0)
            {
                y1 += stepy;
                fraction -= dx;          // same as fraction -= 2*dx
            }
            x1 += stepx;
            fraction += dy;              // same as fraction -= 2*dy
            
            ptCoord = CGPointMake(x1,y1);
            [lineCoordsArray addObject:[NSValue valueWithCGPoint:ptCoord]];
        }
    } else {
        int fraction = dx - (dy >> 1);
        while (y1 != y2) {
            if (fraction >= 0) {
                x1 += stepx;
                fraction -= dy;
            }
            y1 += stepy;
            fraction += dx;
            
            ptCoord = CGPointMake(x1,y1);
            [lineCoordsArray addObject:[NSValue valueWithCGPoint:ptCoord]];
        }
    }
    
    return ([lineCoordsArray copy]); // make the return array immutable
}


#pragma mark - UITextViewDelegate and input methods

//***************************************************
// Synopsis:
//***************************************************
- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text
{
    // Deleting something
    if([text isEqualToString:@""])
    {
        UITextPosition *beginning = textView.beginningOfDocument;
        UITextPosition *start = [textView positionFromPosition:beginning offset:range.location];
        UITextPosition *end = [textView positionFromPosition:start offset:range.length];
        UITextRange *textRange = [textView textRangeFromPosition:start toPosition:end];
        
        NSString *textToReplace = [textView textInRange:textRange];
        
        if ([textToReplace isEqualToString:@">"])
            return NO;
        
        return YES;
    }
    
    if([text isEqualToString:@"\n"])
    {
        // Handle what happens when user presses return
        NSArray *stringArray = [_inputTextView.text componentsSeparatedByString: @">"];
        
        NSArray *lineArray = [self lineArrayForCoordString:[stringArray lastObject]];
        if (lineArray != nil)
        {
            _inputTextView.text = [_inputTextView.text stringByAppendingString:@"\n>"];

            [self prepareCellStringsFromLineArray:lineArray];
        }
        else
        {
            // houston, we have a problem or a command...
            [self handleCommand:[stringArray lastObject]];
        }

        return NO;
    }
    
    return YES;
}


//***************************************************
// Synopsis:
//***************************************************
-(void)handleCommand:(NSString*)command
{
    NSString *output = nil;
    
    if ([command isEqualToString:kCommandPacman])
    {
        [self prepareCellStringsFromString:_pacmanGridString];
    }
    else if ([command isEqualToString:kCommandExplode])
    {
        [self prepareCellStringsFromString:_explodeGridString];
    }
    else if ([command isEqualToString:kCommandAbout])
    {
        [self prepareCellStringsFromString:_aboutGridString];
        output = _aboutString;
    }
    else if ([command isEqualToString:kCommandTetris])
    {
        [self prepareCellStringsFromString:_tetrisGridString];
    }
    else if ([command isEqualToString:kCommandRandom])
    {
        NSString *coordsString = [self generateRandomLinesStringForCount:kRandomLinesCount];
        NSArray *lineArray = [self lineArrayForCoordString:coordsString];
        [self prepareCellStringsFromLineArray:lineArray];
        output = coordsString;
    }
    else if ([command isEqualToString:kCommandClear])
    {
        [self clearCellStrings];
        [self refreshCells];
    }
    else if ([command isEqualToString:kCommandHelp])
    {
        output = _helpString;
    }
    else if ([command isEqualToString:kCommandWelcome])
    {
        output = _helloString;
    }
    else
    {
        output = _infoString;
    }
    
    // Write output to the textView
    if (output != nil)
    {
        _inputTextView.text = [_inputTextView.text stringByAppendingString:@"\n"];
        _inputTextView.text = [_inputTextView.text stringByAppendingString:output];
    }
    _inputTextView.text = [_inputTextView.text stringByAppendingString:@"\n>"];
}


@end
