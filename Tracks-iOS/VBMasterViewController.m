//
//  VBMasterViewController.m
//  Tracks-iOS
//
//  Created by Ariel Rodriguez on 7/7/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "VBMasterViewController.h"

#import "VBDetailViewController.h"

@interface VBMasterViewController ()
- (void)fetchedResultsController:(NSFetchedResultsController *)fetchedResultsController 
                   configureCell:(UITableViewCell *)theCell 
                     atIndexPath:(NSIndexPath *)theIndexPath;
- (NSFetchedResultsController *)fetchedResultsControllerForTableView:(UITableView *)tableView; 
- (NSFetchedResultsController *)freshFetchedResultsControllerWithSearch:(NSString *)searchString; 
- (void)filterContentForSearchText:(NSString *)searchText 
                             scope:(NSInteger)scope; 
@end

@implementation VBMasterViewController

@synthesize detailViewController = _detailViewController;
@synthesize fetchedResultsController = __fetchedResultsController;
@synthesize managedObjectContext = __managedObjectContext;
@synthesize searchFetchedResultsController = __searchFetchedResultsController; 

- (id)initWithNibName:(NSString *)nibNameOrNil 
               bundle:(NSBundle *)nibBundleOrNil {
  self = [super initWithNibName:nibNameOrNil 
                         bundle:nibBundleOrNil];
  if (self) {
    [self setTitle:@"Tracks"]; 
  }
  return self;
}

- (void)viewDidLoad {
  [super viewDidLoad];
  
  [[self navigationItem] setLeftBarButtonItem:[self editButtonItem]]; 
  
  UIBarButtonItem *addButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd 
                                                                             target:self 
                                                                             action:@selector(insertNewObject:)];
  [[self navigationItem] setRightBarButtonItem:addButton];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
  return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
}

- (void)insertNewObject:(id)sender {
  return; 
  NSManagedObjectContext *context = [self.fetchedResultsController managedObjectContext];
  NSEntityDescription *entity = [[self.fetchedResultsController fetchRequest] entity];
  NSManagedObject *newManagedObject = [NSEntityDescription insertNewObjectForEntityForName:[entity name] inManagedObjectContext:context];
  
  // If appropriate, configure the new managed object.
  // Normally you should use accessor methods, but using KVC here avoids the need to add a custom class to the template.
  [newManagedObject setValue:[NSDate date] forKey:@"artistName"];
  
  // Save the context.
  NSError *error = nil;
  if (![context save:&error]) {
    // Replace this implementation with code to handle the error appropriately.
    // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development. 
    NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
    abort();
  }
}

#pragma mark - Table View
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
  
  return [[[self fetchedResultsControllerForTableView:tableView] sections] count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
  id <NSFetchedResultsSectionInfo> sectionInfo = [[[self fetchedResultsControllerForTableView:tableView] sections] objectAtIndex:section];
  return [sectionInfo numberOfObjects];
}

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView 
         cellForRowAtIndexPath:(NSIndexPath *)indexPath {
  static NSString *CellIdentifier = @"Cell";
  
  UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
  if (cell == nil) {
    cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
  }
  
  [self fetchedResultsController:[self fetchedResultsControllerForTableView:tableView]
                   configureCell:cell
                     atIndexPath:indexPath]; 
  
  return cell;
}

- (BOOL)tableView:(UITableView *)tableView 
canEditRowAtIndexPath:(NSIndexPath *)indexPath {
  return YES;
}

- (BOOL)tableView:(UITableView *)tableView 
canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
  // The table view should not be re-orderable.
  return NO;
}

- (void)tableView:(UITableView *)tableView 
commitEditingStyle:(UITableViewCellEditingStyle)editingStyle
forRowAtIndexPath:(NSIndexPath *)indexPath {
  if ( editingStyle == UITableViewCellEditingStyleDelete ) {
    NSManagedObjectContext *context = [[self fetchedResultsController] managedObjectContext];
    [context deleteObject:[[self fetchedResultsController] objectAtIndexPath:indexPath]];
    
    NSError *error = nil;
    if (![context save:&error]) {
      NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
      abort();
    }
  }   
}

- (void)tableView:(UITableView *)tableView 
didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
  if (![self detailViewController]) {
    [self setDetailViewController:[[VBDetailViewController alloc] initWithNibName:@"VBDetailViewController" bundle:nil]];
  }
  NSManagedObject *object = [[self fetchedResultsController] objectAtIndexPath:indexPath];
  [[self detailViewController] setDetailItem:object];
  [[self navigationController] pushViewController:[self detailViewController]
                                         animated:YES];
}

- (NSString *)tableView:(UITableView *)tableView 
titleForHeaderInSection:(NSInteger)section {
  NSString *sectionTitle = [[[[self fetchedResultsController] sections] objectAtIndex:section] name];
  return sectionTitle;
}

#pragma mark - Fetched results controller

- (NSFetchedResultsController *)fetchedResultsController {
  if (__fetchedResultsController != nil) {
    return __fetchedResultsController;
  }
  __fetchedResultsController = [self freshFetchedResultsControllerWithSearch:nil]; 
  return __fetchedResultsController; 
} 

- (NSFetchedResultsController *)searchFetchedResultsController {
  if (__searchFetchedResultsController != nil) {
    return __searchFetchedResultsController;
  }
  __searchFetchedResultsController = [self freshFetchedResultsControllerWithSearch:[[[self searchDisplayController] searchBar] text]]; 
  return __searchFetchedResultsController; 
} 

- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller {
  [[self tableView] beginUpdates];
}

- (void)controller:(NSFetchedResultsController *)controller
  didChangeSection:(id <NSFetchedResultsSectionInfo>)sectionInfo
           atIndex:(NSUInteger)sectionIndex
     forChangeType:(NSFetchedResultsChangeType)type {
  switch(type) {
    case NSFetchedResultsChangeInsert:
      [[self tableView] insertSections:[NSIndexSet indexSetWithIndex:sectionIndex]
                      withRowAnimation:UITableViewRowAnimationFade];
      break;
      
    case NSFetchedResultsChangeDelete:
      [[self tableView] deleteSections:[NSIndexSet indexSetWithIndex:sectionIndex]
                      withRowAnimation:UITableViewRowAnimationFade];
      break;
  }
}

- (void)controller:(NSFetchedResultsController *)controller
   didChangeObject:(id)anObject
       atIndexPath:(NSIndexPath *)indexPath 
     forChangeType:(NSFetchedResultsChangeType)type
      newIndexPath:(NSIndexPath *)newIndexPath {
  //TODO: identify if the table view is the search table view or the simple one
  UITableView *tableView = [self tableView];
  
  switch(type) {
    case NSFetchedResultsChangeInsert:
      [tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:newIndexPath]
                       withRowAnimation:UITableViewRowAnimationFade];
      break;
      
    case NSFetchedResultsChangeDelete:
      [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] 
                       withRowAnimation:UITableViewRowAnimationFade];
      break;
      
    case NSFetchedResultsChangeUpdate:
      [self fetchedResultsController:[self fetchedResultsControllerForTableView:tableView]
                       configureCell:[tableView cellForRowAtIndexPath:indexPath]
                         atIndexPath:indexPath];
      break;
      
    case NSFetchedResultsChangeMove:
      [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath]
                       withRowAnimation:UITableViewRowAnimationFade];
      [tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:newIndexPath]
                       withRowAnimation:UITableViewRowAnimationFade];
      break;
  }
}

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller {
  [self.tableView endUpdates];
}

- (void)fetchedResultsController:(NSFetchedResultsController *)fetchedResultsController 
                   configureCell:(UITableViewCell *)cell 
                     atIndexPath:(NSIndexPath *)indexPath {
  NSManagedObject *object = [fetchedResultsController objectAtIndexPath:indexPath];
  [[cell textLabel] setText:[object valueForKey:@"trackName"]]; 
}

#pragma mark - Search Display Controller 
- (BOOL)searchDisplayController:(UISearchDisplayController *)controller 
shouldReloadTableForSearchString:(NSString *)searchString {
  [self filterContentForSearchText:searchString
                             scope:[[controller searchBar] selectedScopeButtonIndex]]; 
  return YES;
}

- (BOOL)searchDisplayController:(UISearchDisplayController *)controller 
shouldReloadTableForSearchScope:(NSInteger)searchOption {
  [self filterContentForSearchText:[[controller searchBar] text]
                             scope:searchOption]; 
  return YES; 
}

- (NSFetchedResultsController *)fetchedResultsControllerForTableView:(UITableView *)tv {
  return [tv isEqual:[self tableView]] ? [self fetchedResultsController] : [self searchFetchedResultsController];  
}

- (void)filterContentForSearchText:(NSString *)searchText 
                             scope:(NSInteger)scope {
  [[self searchFetchedResultsController] setDelegate:nil];
  [self setSearchFetchedResultsController:nil];
}

- (NSFetchedResultsController *)freshFetchedResultsControllerWithSearch:(NSString *)searchString {
  NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
  NSEntityDescription *entity = [NSEntityDescription entityForName:@"Track"
                                            inManagedObjectContext:self.managedObjectContext];
  [fetchRequest setEntity:entity];

  [fetchRequest setFetchBatchSize:20];
  NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"artistName" 
                                                                 ascending:NO];
  NSArray *sortDescriptors = [NSArray arrayWithObjects:sortDescriptor, nil];
  
  [fetchRequest setSortDescriptors:sortDescriptors];
  
  if ( [searchString length] > 0 ) {
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"artistName CONTAINS[cd] %@", searchString]; 
    [fetchRequest setPredicate:predicate]; 
  }

  [NSFetchedResultsController deleteCacheWithName:@"Master"];
  NSFetchedResultsController *aFetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest 
                                                                                              managedObjectContext:self.managedObjectContext 
                                                                                                sectionNameKeyPath:@"artistName" 
                                                                                                         cacheName:@"Master"];
  [aFetchedResultsController setDelegate:self]; 
  [self setFetchedResultsController:aFetchedResultsController]; 
  
	NSError *error = nil;
	if (![[self fetchedResultsController] performFetch:&error]) {
    // Replace this implementation with code to handle the error appropriately.
    // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development. 
    NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
    abort();
	}
  
  return aFetchedResultsController;
}

@end
