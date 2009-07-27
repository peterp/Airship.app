//
//  DirectoryTableViewController.m
//  Humboldt
//
//  Created by Peter Pistorius on 2009/06/27.
//  Copyright 2009 appfactory. All rights reserved.
//

#import "DirectoryTableViewController.h"
#import "DirectoryItem.h"

#import "DetailViewController.h"
#import "DocumentViewController.h"
#import "MediaViewController.h"


@implementation DirectoryTableViewController

@synthesize relativePath, absolutePath, directoryItems, filteredDirectoryItems;



# pragma mark -
# pragma mark Setup / Tear down

- (void)viewDidLoad 
{
	[super viewDidLoad];
	
	// TableView setup
	self.title = [self.relativePath lastPathComponent];
	self.tableView.rowHeight = 44;

	// Data source
	self.absolutePath = [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0] stringByAppendingPathComponent:self.relativePath];
	NSArray *directoryContents = [[NSFileManager defaultManager] directoryContentsAtPath:self.absolutePath];
	self.directoryItems = [NSMutableArray array];
	for (NSString *name in [directoryContents sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)]) {
		if (![name isEqualToString:@".DS_Store"]) {
			// Create DirectoryItem
			[self.directoryItems addObject:[DirectoryItem initWithName:name atPath:self.absolutePath]];
		}
	}
	
	// Search
	searchBar = [[UISearchBar alloc] initWithFrame:self.tableView.bounds];
	searchBar.delegate = self;
	searchBar.placeholder	= [@"Search " stringByAppendingString:self.title];
	[searchBar sizeToFit];
	self.tableView.tableHeaderView = searchBar;
	searchDisplayController = [[UISearchDisplayController alloc] initWithSearchBar:searchBar contentsController:self];
	searchDisplayController.searchResultsDelegate = self;
	searchDisplayController.searchResultsDataSource = self;
	searchDisplayController.delegate = self;
	self.filteredDirectoryItems = [NSMutableArray array];
	
	// Notifications
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(newItem:) name:@"newItem" object:nil];
}


- (void)dealloc 
{
	self.absolutePath = nil;
	self.relativePath = nil;
	self.directoryItems = nil;
	self.filteredDirectoryItems = nil;
	
	[super dealloc];
}



#pragma mark -
#pragma mark UITableView data source and delegate methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView 
{
	if (tableView == self.searchDisplayController.searchResultsTableView) {
		return 1;
	} else {
		return 1;
	}	
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section 
{
	if (tableView == self.searchDisplayController.searchResultsTableView) {
		return [self.filteredDirectoryItems count];
	} else {
		return [self.directoryItems count];
	}
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath 
{
	// Custom labels
	UILabel *nameLabel;
	UILabel *metaLabel;
    
	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell"];
  if (cell == nil) {
		// Create cell
		cell = [[[UITableViewCell alloc] initWithFrame:CGRectZero reuseIdentifier:@"Cell"] autorelease];
		
		// Name 
		nameLabel = [[[UILabel alloc] initWithFrame:CGRectMake(40, 0, 250, 22)] autorelease];
		nameLabel.tag = 1001;
		nameLabel.font = [UIFont systemFontOfSize:[UIFont labelFontSize] - 2];
		nameLabel.textColor = [UIColor blackColor];
		[cell.contentView addSubview:nameLabel];
		
		// Meta
		metaLabel = [[[UILabel alloc] initWithFrame:CGRectMake(40, 22, 120, 22)] autorelease];
		metaLabel.tag = 1002;
		metaLabel.font = [UIFont systemFontOfSize:[UIFont labelFontSize] - 4];
		metaLabel.textColor = [UIColor grayColor];
		[cell.contentView addSubview:metaLabel];
			
	} else {
		// Restore cell
		nameLabel = (UILabel *)[cell viewWithTag:1001];
		metaLabel = (UILabel *)[cell viewWithTag:1002];
	}
	
	// Item
	DirectoryItem *item = nil;
	if (tableView == self.searchDisplayController.searchResultsTableView) {
		item = [self.filteredDirectoryItems objectAtIndex:indexPath.row];
	}	else {
		item = [self.directoryItems objectAtIndex:indexPath.row];
	}
	[cell.imageView initWithImage:[UIImage imageNamed:[item.type stringByAppendingPathExtension:@"png"]]];
	nameLabel.text = item.name;
	metaLabel.text = item.date;

	return cell;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath 
{

	DirectoryItem *item = nil;
	if (tableView == self.searchDisplayController.searchResultsTableView) {
		item = [self.filteredDirectoryItems objectAtIndex:indexPath.row];
	}	else {
		item = [self.directoryItems objectAtIndex:indexPath.row];
	}
	
	if ([item.type isEqualToString:@"directory"]) {
		// Directory
		DirectoryTableViewController *directoryTableViewController = [[DirectoryTableViewController alloc] initWithNibName:nil bundle:[NSBundle mainBundle]];
		directoryTableViewController.relativePath = [self.relativePath stringByAppendingPathComponent:item.name];
		[self.navigationController pushViewController:directoryTableViewController animated:YES];
		[directoryTableViewController release];
		
	} else if ([item.type isEqualToString:@"document"]) {
		
		DocumentViewController *documentViewController = [[DocumentViewController alloc] initWithNibName:nil bundle:[NSBundle mainBundle]];
		[self.navigationController pushViewController:documentViewController animated:YES];
		[documentViewController openFile:item];
		[documentViewController release];
	
	} else if ([item.type isEqualToString:@"video"]) {
	
		MediaViewController *mediaViewController= [[MediaViewController alloc] initWithNibName:nil bundle:[NSBundle mainBundle]];
		[self.navigationController pushViewController:mediaViewController animated:YES];
		[mediaViewController openFile:item];
		[mediaViewController release];
	
	} else {
		// File
		
		// Create a new detail view controller
		DetailViewController *detailViewController = [[DetailViewController alloc] initWithNibName:nil bundle:[NSBundle mainBundle]];
		[detailViewController openFile:item];
		[self.navigationController pushViewController:detailViewController animated:YES];
		
		[detailViewController release];
	}
}



#pragma mark -
#pragma mark Content Filtering

- (void)filterContentForSearchText:(NSString*)searchText
{
	[self.filteredDirectoryItems removeAllObjects];
	for (DirectoryItem *item in self.directoryItems) {
		// Compare
		NSComparisonResult result = [item.name compare:searchText options:(NSCaseInsensitiveSearch|NSDiacriticInsensitiveSearch) range:NSMakeRange(0, [searchText length])];
		if (result == NSOrderedSame) {
			[self.filteredDirectoryItems addObject:item];
		}
	}
}



#pragma mark -
#pragma mark UISearchDisplayController Delegate Methods

- (BOOL)searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchString:(NSString *)searchString 
{
	[self filterContentForSearchText:searchString];
	return YES;
}

















/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/


/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:YES];
    }   
    else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/


/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
}
*/


/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

# pragma mark - 
# pragma mark Getters, setters, and helper methods



//- (void)setRelativePath:(NSString *)path
//{
//	// Absolute path is based on relative path
//	relativePath = path;
//	NSLog(@"setRelativePath: %@", relativePath);
//	
//}


- (void)newItem:(NSNotification *)notification 
{

	NSLog(@"%@, %@", self.relativePath, notification.userInfo);

	// Not for this view, return;
	if (![[notification.userInfo valueForKey:@"relativePath"] isEqualToString:self.relativePath]) {
		return;
	}

	NSString *name = [notification.userInfo valueForKey:@"name"];
	int indexRow = 0;
	for (int i = 0; [self.directoryItems count] > i; i++) {
	
		
		DirectoryItem *item = [self.directoryItems objectAtIndex:i];
	
		if ([name compare:item.name options:NSCaseInsensitiveSearch|NSDiacriticInsensitiveSearch] < 1) {
			indexRow = i;
			break;
		}
		
		if (i == [self.directoryItems count] - 1) {
			// Place at end
			indexRow = i + 1;
			break;
		}
	}
	
	// No other files to compare against.
	[self.directoryItems insertObject:[DirectoryItem initWithName:name atPath:self.absolutePath] atIndex:indexRow];
	[self.tableView beginUpdates];
	[self.tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForRow:indexRow inSection:0]]	withRowAnimation:UITableViewRowAnimationRight];
	[self.tableView endUpdates];
	
}








/*
- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
}
*/
/*
- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
}
*/
/*
- (void)viewWillDisappear:(BOOL)animated {
	[super viewWillDisappear:animated];
}
*/
/*
- (void)viewDidDisappear:(BOOL)animated {
	[super viewDidDisappear:animated];
}
*/

/*
// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}
*/

- (void)didReceiveMemoryWarning {
	// Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
	
	// Release any cached data, images, etc that aren't in use.
}

- (void)viewDidUnload {
	// Release any retained subviews of the main view.
	// e.g. self.myOutlet = nil;
}


@end

