/*
 * Copyright (c) 2015, Nordic Semiconductor
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 *
 * 1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 *
 * 2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the
 * documentation and/or other materials provided with the distribution.
 *
 * 3. Neither the name of the copyright holder nor the names of its contributors may be used to endorse or promote products derived from this
 * software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
 * HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
 * LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON
 * ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE
 * USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "UserFilesTableViewController.h"
#import "AccessFileSystem.h"
#import "Utility.h"
#import "FolderFilesTableViewController.h"
//#import "PageImageViewController.h"


@interface UserFilesTableViewController ()

@property (nonatomic,strong)NSMutableArray *files;
@property (nonatomic,strong)NSString *documentsDirectoryPath;
@property (nonatomic, strong)AccessFileSystem *fileSystem;

@end

@implementation UserFilesTableViewController

int PAGE_NUMBERS;

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self.tableView setBackgroundView:[[UIImageView alloc]initWithImage:[UIImage imageNamed:@"Background"]]];
    self.fileSystem = [[AccessFileSystem alloc]init];
    self.documentsDirectoryPath = [self.fileSystem getDocumentsDirectoryPath];
    self.files = [[self.fileSystem getDirectoriesAndRequiredFilesFromDocumentsDirectory] mutableCopy];
    self.navigationItem.rightBarButtonItem = self.editButtonItem;
    /*if (self.files.count == 0) {
        [self showAddFilesDemo];
    }*/
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be re:created.
}

- (void) setEmptyTableMessage
{
    self.emptyMessageText.hidden = NO;
    self.emptyMessageText.editable = YES;
    [self.emptyMessageText setFont:[UIFont systemFontOfSize:18.0]];
    self.emptyMessageText.text = [Utility getEmptyUserFilesText];
    self.emptyMessageText.editable = NO;
}

-(void) hideNavigationBar
{
    [self.navigationController setNavigationBarHidden:YES];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)sectionred
{
    if (self.files.count == 0) {
        [self setEmptyTableMessage];
        self.navigationItem.rightBarButtonItem.enabled = NO;
    }
    else {
        self.emptyMessageText.hidden = YES;
        self.navigationItem.rightBarButtonItem.enabled = YES;
    }
    return self.files.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"UserFilesCell" forIndexPath:indexPath];
    
    // Configure the cell...
    NSString *fileName = [self.files objectAtIndex:indexPath.row];
    NSString *filePath = [self.documentsDirectoryPath stringByAppendingPathComponent:fileName];
    if ([self.fileSystem isDirectory:filePath]) {
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        if ([fileName isEqualToString:@"Inbox"]) {
            cell.imageView.image = [UIImage imageNamed:@"emailFolder"];
        }
        else {
            cell.imageView.image = [UIImage imageNamed:@"folder"];
        }        
    }
    else if ([self.fileSystem checkFileExtension:fileName fileExtension:HEX]) {
        cell.imageView.image = [UIImage imageNamed:@"file"];
    }
    else if ([self.fileSystem checkFileExtension:fileName fileExtension:BIN]) {
        cell.imageView.image = [UIImage imageNamed:@"file"];
    }
    else if ([self.fileSystem checkFileExtension:fileName fileExtension:ZIP]) {
        cell.imageView.image = [UIImage imageNamed:@"zipFile"];
    }
    cell.textLabel.text = [self.files objectAtIndex:indexPath.row];
    return cell;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *fileName = [self.files objectAtIndex:indexPath.row];
    NSString *filePath = [self.documentsDirectoryPath stringByAppendingPathComponent:fileName];
    
    if (![self.fileSystem isDirectory:filePath]) {
        NSURL *fileURL = [NSURL fileURLWithPath:filePath];
        [self.fileDelegate onFileSelected:fileURL];
        [self dismissViewControllerAnimated:YES completion:nil];;
    }    
}

-(void)setEditing:(BOOL)editing animated:(BOOL)animated
{
    [super setEditing:editing animated:animated];
    NSLog(@"setEditing");
    [self.tableView setEditing:editing animated:YES];
}

-(UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSLog(@"editingStyleForRowAtIndexPath");
    return UITableViewCellEditingStyleDelete;
}

-(void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSLog(@"commitEditingStyle");
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        NSString *fileName = [self.files objectAtIndex:indexPath.row];
        if (![fileName isEqualToString:@"Inbox"]) {
            NSLog(@"Removing file: %@",fileName);
            [self.files removeObjectAtIndex:indexPath.row];
            NSString *filePath = [self.documentsDirectoryPath stringByAppendingPathComponent:fileName];
            NSLog(@"Removing file from path %@",filePath);
            [self.fileSystem deleteFile:filePath];
            [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
        }
        else {
            NSLog(@"Cant remove Inbox directory");
            [Utility showAlert:@"User can't delete Inbox directory"];
            [tableView reloadData];
        }
        
    }
}


 #pragma mark - Navigation

-(BOOL)shouldPerformSegueWithIdentifier:(NSString *)identifier sender:(id)sender
{
    NSIndexPath *selectionIndexPath = [self.tableView indexPathForSelectedRow];
    NSString *fileName = [self.files objectAtIndex:selectionIndexPath.row];
    NSString *filePath = [self.documentsDirectoryPath stringByAppendingPathComponent:fileName];
    if ([self.fileSystem isDirectory:filePath]) {
        return YES;
    }
    return NO;
}
 
 // In a storyboard-based application, you will often want to do a little preparation before navigation
 - (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
 {
     NSIndexPath *selectionIndexPath = [self.tableView indexPathForSelectedRow];
     NSString *fileName = [self.files objectAtIndex:selectionIndexPath.row];
     NSString *filePath = [self.documentsDirectoryPath stringByAppendingPathComponent:fileName];
     if ([self.fileSystem isDirectory:filePath]) {
         FolderFilesTableViewController *folderVC = [segue destinationViewController];
         folderVC.directoryPath = filePath;
         folderVC.files = [[self.fileSystem getRequiredFilesFromDirectory:filePath] mutableCopy];
         folderVC.fileDelegate = self.fileDelegate;
     }
 }
 

- (IBAction)cancelBarButtonPressed:(UIBarButtonItem *)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
