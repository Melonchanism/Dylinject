//
//  main.m
//  test
//
//  Created by Dora Orak on 20.02.2025.
//

#import <AppKit/AppKit.h>
#import <CommonCrypto/CommonDigest.h>
#import <Foundation/Foundation.h>
#include <dlfcn.h>
#include <mach/mach.h>
#include <mach/mach_vm.h>
#include <pthread/pthread.h>
#include <stdio.h>

#include <ptrauth.h>
kern_return_t (*_thread_convert_thread_state)(thread_act_t thread, int direction, thread_state_flavor_t flavor,
																							thread_state_t in_state, mach_msg_type_number_t in_stateCnt,
																							thread_state_t out_state, mach_msg_type_number_t *out_stateCnt);

static char shell_code[] = "\xFF\xC3\x00\xD1"                 // sub        sp, sp, #0x30
"\xFD\x7B\x02\xA9"                 // stp        x29, x30, [sp, #0x20]
"\xFD\x83\x00\x91"                 // add        x29, sp, #0x20
"\xA0\xC3\x1F\xB8"                 // stur       w0, [x29, #-0x4]
"\xE1\x0B\x00\xF9"                 // str        x1, [sp, #0x10]
"\xE0\x23\x00\x91"                 // add        x0, sp, #0x8
"\x08\x00\x80\xD2"                 // mov        x8, #0
"\xE8\x07\x00\xF9"                 // str        x8, [sp, #0x8]
"\xE1\x03\x08\xAA"                 // mov        x1, x8
"\xE2\x01\x00\x10"                 // adr        x2, #0x3C
"\xE2\x23\xC1\xDA"                 // paciza     x2
"\xE3\x03\x08\xAA"                 // mov        x3, x8
"\x49\x01\x00\x10"                 // adr        x9, #0x28 ; pthread_create_from_mach_thread
"\x29\x01\x40\xF9"                 // ldr        x9, [x9]
"\x20\x01\x3F\xD6"                 // blr        x9
"\xA0\x4C\x8C\xD2"                 // movz       x0, #0x6265
"\x20\x2C\xAF\xF2"                 // movk       x0, #0x7961, lsl #16
"\x09\x00\x00\x10"                 // adr        x9, #0
"\x20\x01\x1F\xD6"                 // br         x9
"\xFD\x7B\x42\xA9"                 // ldp        x29, x30, [sp, #0x20]
"\xFF\xC3\x00\x91"                 // add        sp, sp, #0x30
"\xC0\x03\x5F\xD6"                 // ret
"\x00\x00\x00\x00\x00\x00\x00\x00" //
"\x7F\x23\x03\xD5"                 // pacibsp
"\xFF\xC3\x00\xD1"                 // sub        sp, sp, #0x30
"\xFD\x7B\x02\xA9"                 // stp        x29, x30, [sp, #0x20]
"\xFD\x83\x00\x91"                 // add        x29, sp, #0x20
"\xA0\xC3\x1F\xB8"                 // stur       w0, [x29, #-0x4]
"\xE1\x0B\x00\xF9"                 // str        x1, [sp, #0x10]
"\x21\x00\x80\xD2"                 // mov        x1, #1
"\x60\x01\x00\x10"                 // adr        x0, #0x2c ; payload_path
"\x09\x01\x00\x10"                 // adr        x9, #0x20 ; dlopen
"\x29\x01\x40\xF9"                 // ldr        x9, [x9]
"\x20\x01\x3F\xD6"                 // blr        x9
"\x09\x00\x80\x52"                 // mov        w9, #0
"\xE0\x03\x09\xAA"                 // mov        x0, x9
"\xFD\x7B\x42\xA9"                 // ldp        x29, x30, [sp, #0x20]
"\xFF\xC3\x00\x91"                 // add        sp, sp, #0x30
"\xFF\x0F\x5F\xD6"                 // retab
"\x00\x00\x00\x00\x00\x00\x00\x00" //
"\x00\x00\x00\x00\x00\x00\x00\x00" // empty space for payload_path
"\x00\x00\x00\x00\x00\x00\x00\x00"
"\x00\x00\x00\x00\x00\x00\x00\x00"
"\x00\x00\x00\x00\x00\x00\x00\x00"
"\x00\x00\x00\x00\x00\x00\x00\x00"
"\x00\x00\x00\x00\x00\x00\x00\x00"
"\x00\x00\x00\x00\x00\x00\x00\x00"
"\x00\x00\x00\x00\x00\x00\x00\x00"
"\x00\x00\x00\x00\x00\x00\x00\x00"
"\x00\x00\x00\x00\x00\x00\x00\x00"
"\x00\x00\x00\x00\x00\x00\x00\x00"
"\x00\x00\x00\x00\x00\x00\x00\x00"
"\x00\x00\x00\x00\x00\x00\x00\x00"
"\x00\x00\x00\x00\x00\x00\x00\x00"
"\x00\x00\x00\x00\x00\x00\x00\x00"
"\x00\x00\x00\x00\x00\x00\x00\x00"
"\x00\x00\x00\x00\x00\x00\x00\x00"
"\x00\x00\x00\x00\x00\x00\x00\x00"
"\x00\x00\x00\x00\x00\x00\x00\x00"
"\x00\x00\x00\x00\x00\x00\x00\x00"
"\x00\x00\x00\x00\x00\x00\x00\x00"
"\x00\x00\x00\x00\x00\x00\x00\x00"
"\x00\x00\x00\x00\x00\x00\x00\x00"
"\x00\x00\x00\x00\x00\x00\x00\x00"
"\x00\x00\x00\x00\x00\x00\x00\x00"
"\x00\x00\x00\x00\x00\x00\x00\x00"
"\x00\x00\x00\x00\x00\x00\x00\x00"
"\x00\x00\x00\x00\x00\x00\x00\x00"
"\x00\x00\x00\x00\x00\x00\x00\x00"
"\x00\x00\x00\x00\x00\x00\x00\x00"
"\x00\x00\x00\x00\x00\x00\x00\x00"
"\x00\x00\x00\x00\x00\x00\x00\x00"
"\x00\x00\x00\x00\x00\x00\x00\x00"
"\x00\x00\x00\x00\x00\x00\x00\x00"
"\x00\x00\x00\x00\x00\x00\x00\x00"
"\x00\x00\x00\x00\x00\x00\x00\x00";

// This function totally wasn't vibe coded
NSString *sha256ForFileAtPath(NSString *filePath) {
	NSFileHandle *fileHandle = [NSFileHandle fileHandleForReadingAtPath:filePath];
	if (!fileHandle)
		return nil;
	
	CC_SHA256_CTX shaContext;
	CC_SHA256_Init(&shaContext);
	
	while (true) {
		@autoreleasepool {
			NSData *fileData = [fileHandle readDataOfLength:4096];
			if ([fileData length] == 0)
				break;
			CC_SHA256_Update(&shaContext, [fileData bytes], (CC_LONG)[fileData length]);
		}
	}
	
	unsigned char hash[CC_SHA256_DIGEST_LENGTH];
	CC_SHA256_Final(hash, &shaContext);
	
	NSMutableString *output = [NSMutableString stringWithCapacity:CC_SHA256_DIGEST_LENGTH * 2];
	for (int i = 0; i < CC_SHA256_DIGEST_LENGTH; i++) {
		[output appendFormat:@"%02x", hash[i]];
	}
	
	return [output copy];
}

void printUsage(char **argv) {
	printf("Usage: \033[33msudo\033[0m %s \033[32m<bundle id> <dylib path> \033[0m(Optional)\033[32m<sha256sum of dylib>\033[0m\n", argv[0]);
	printf("       File path must be absolute or based on ~\n");
}

int main(int argc, char **argv) {
	
	if (argc < 3) {
		printUsage(argv);
		return 1;
	}
	
	int result = 0;
	mach_port_t task = 0;
	thread_act_t thread = 0;
	mach_vm_address_t code = 0;
	mach_vm_address_t stack = 0;
	vm_size_t stack_size = 16 * 1024;
	uint64_t stack_contents = 0x00000000CAFEBABE;
	
	NSString *filePath = [NSString stringWithCString:argv[2]];
	NSString *unwrappedPath = [filePath stringByExpandingTildeInPath];
	const char *payload_path = [unwrappedPath cString];
	NSString *bundleID = [NSString stringWithCString:argv[1]];
	NSArray<NSRunningApplication *> *processes = [NSRunningApplication runningApplicationsWithBundleIdentifier:bundleID];
	pid_t pid = -1;
	if ([processes count] == 1) {
		pid = [[processes firstObject] processIdentifier];
	}
	
	// Optional hash checking for sudoers.d security
	if (argc == 4) {
		NSString *inputHash = [NSString stringWithCString:argv[3]];
		NSFileManager *fileManager = [NSFileManager defaultManager];
		if ([fileManager fileExistsAtPath:unwrappedPath]) {
		} else {
			printf("File not Found");
			return 1;
		}
		if ([sha256ForFileAtPath(unwrappedPath) hash] != [inputHash hash]) {
			fprintf(stderr, "sha256sum doesn't match\n");
			return 1;
		}
	}
	
	if (task_for_pid(mach_task_self(), pid, &task) != KERN_SUCCESS) {
		fprintf(stderr, "could not retrieve task port for pid: %d\n", pid);
		return 1;
	}
	
	if (mach_vm_allocate(task, &stack, stack_size, VM_FLAGS_ANYWHERE) != KERN_SUCCESS) {
		fprintf(stderr, "could not allocate stack segment\n");
		return 1;
	}
	
	if (mach_vm_write(task, stack, (vm_address_t)&stack_contents, sizeof(uint64_t)) != KERN_SUCCESS) {
		fprintf(stderr, "could not copy dummy return address into stack segment\n");
		return 1;
	}
	
	if (vm_protect(task, stack, stack_size, 1, VM_PROT_READ | VM_PROT_WRITE) != KERN_SUCCESS) {
		fprintf(stderr, "could not change protection for stack segment\n");
		return 1;
	}
	
	if (mach_vm_allocate(task, &code, sizeof(shell_code), VM_FLAGS_ANYWHERE) != KERN_SUCCESS) {
		fprintf(stderr, "could not allocate code segment\n");
		return 1;
	}
	
	uint64_t pcfmt_address =
	(uint64_t)ptrauth_strip(dlsym(RTLD_DEFAULT, "pthread_create_from_mach_thread"), ptrauth_key_function_pointer);
	uint64_t dlopen_address = (uint64_t)ptrauth_strip(dlsym(RTLD_DEFAULT, "dlopen"), ptrauth_key_function_pointer);
	
	memcpy(shell_code + 88, &pcfmt_address, sizeof(uint64_t));
	memcpy(shell_code + 160, &dlopen_address, sizeof(uint64_t));
	memcpy(shell_code + 168, payload_path, strlen(payload_path));
	
	if (mach_vm_write(task, code, (vm_address_t)shell_code, sizeof(shell_code)) != KERN_SUCCESS) {
		fprintf(stderr, "could not copy shellcode into code segment\n");
		return 1;
	}
	
	if (vm_protect(task, code, sizeof(shell_code), 0, VM_PROT_EXECUTE | VM_PROT_READ) != KERN_SUCCESS) {
		fprintf(stderr, "could not change protection for code segment\n");
		return 1;
	}
	
	void *handle = dlopen("/usr/lib/system/libsystem_kernel.dylib", RTLD_GLOBAL | RTLD_LAZY);
	if (handle) {
		_thread_convert_thread_state = dlsym(handle, "thread_convert_thread_state");
		dlclose(handle);
	}
	
	if (!_thread_convert_thread_state) {
		fprintf(stderr, "could not load symbol: thread_convert_thread_state\n");
		return 1;
	}
	
	arm_thread_state64_t thread_state = {}, machine_thread_state = {};
	thread_state_flavor_t thread_flavor = ARM_THREAD_STATE64;
	mach_msg_type_number_t thread_flavor_count = ARM_THREAD_STATE64_COUNT,
	machine_thread_flavor_count = ARM_THREAD_STATE64_COUNT;
	
	__darwin_arm_thread_state64_set_pc_fptr(thread_state,
																					ptrauth_sign_unauthenticated((void *)code, ptrauth_key_asia, 0));
	__darwin_arm_thread_state64_set_sp(thread_state, stack + (stack_size / 2));
	
	kern_return_t error = thread_create(task, &thread);
	if (error != KERN_SUCCESS) {
		fprintf(stderr, "could not create remote thread: %s\n", mach_error_string(error));
		return 1;
	}
	
	error = _thread_convert_thread_state(thread, 2, thread_flavor, (thread_state_t)&thread_state, thread_flavor_count,
																			 (thread_state_t)&machine_thread_state, &machine_thread_flavor_count);
	if (error != KERN_SUCCESS) {
		fprintf(stderr, "could not convert thread state: %s\n", mach_error_string(error));
		return 1;
	}
	
	NSOperatingSystemVersion os_version = [[NSProcessInfo processInfo] operatingSystemVersion];
	if ((os_version.majorVersion == 14 && os_version.minorVersion >= 4) || (os_version.majorVersion >= 15)) {
		thread_terminate(thread);
		error = thread_create_running(task, thread_flavor, (thread_state_t)&machine_thread_state,
																	machine_thread_flavor_count, &thread);
		if (error != KERN_SUCCESS) {
			fprintf(stderr, "could not spawn remote thread: %s\n", mach_error_string(error));
			return 1;
		}
	} else {
		error = thread_set_state(thread, thread_flavor, (thread_state_t)&machine_thread_state, machine_thread_flavor_count);
		if (error != KERN_SUCCESS) {
			fprintf(stderr, "could not set thread state: %s\n", mach_error_string(error));
			return 1;
		}
		
		error = thread_resume(thread);
		if (error != KERN_SUCCESS) {
			fprintf(stderr, "could not resume remote thread: %s\n", mach_error_string(error));
			return 1;
		}
	}
	
	usleep(10000);
	
	for (int i = 0; i < 10; ++i) {
		kern_return_t error = thread_get_state(thread, thread_flavor, (thread_state_t)&thread_state, &thread_flavor_count);
		
		if (error != KERN_SUCCESS) {
			result = 1;
			goto terminate;
		}
		
		if (thread_state.__x[0] == 0x79616265) {
			result = 0;
			goto terminate;
		}
		
		usleep(20000);
	}
	
terminate:
	
	error = thread_terminate(thread);
	
	if (error != KERN_SUCCESS) {
		fprintf(stderr, "failed to terminate remote thread: %s\n", mach_error_string(error));
	} else {
		// fprintf(stdout, "terminated remote thread\n");
		exit(0);
	}
	
	return result;
}

