000000000020bf40 <nice_common::cpu_join::pass1_avx2>:
  20bf40:	push   %r15
  20bf42:	push   %r14
  20bf44:	push   %r12
  20bf46:	push   %rbx
  20bf47:	push   %rax
  20bf48:	shl    $0x3,%rdx
  20bf4c:	mov    %edx,%r11d
  20bf4f:	and    $0x3fc0,%r11d
  20bf56:	je     20bfef <nice_common::cpu_join::pass1_avx2+0xaf>
  20bf5c:	vmovq  %rdi,%xmm0
  20bf61:	vpbroadcastq %xmm0,%ymm0
  20bf66:	xor    %r10d,%r10d
  20bf69:	vpxor  %xmm1,%xmm1,%xmm1
  20bf6d:	lea    -0x158ad2(%rip),%rbx        # b34a2 <nice_common::cpu_join::BIT_POS>
  20bf74:	lea    -0x158ce8(%rip),%r14        # b3293 <nice_common::cpu_join::BIT_CNT>
  20bf7b:	mov    %r11,%r15
  20bf7e:	xor    %eax,%eax
  20bf80:	lea    0x8(%rax),%r9
  20bf84:	cmp    $0xfffffffffffffff7,%rax
  20bf88:	ja     20c034 <nice_common::cpu_join::pass1_avx2+0xf4>
  20bf8e:	cmp    %r8,%r9
  20bf91:	ja     20c034 <nice_common::cpu_join::pass1_avx2+0xf4>
  20bf97:	vpand  0x20(%rsi,%r10,8),%ymm0,%ymm2
  20bf9e:	vpand  (%rsi,%r10,8),%ymm0,%ymm3
  20bfa4:	vpcmpeqq %ymm1,%ymm3,%ymm3
  20bfa9:	vpcmpeqq %ymm1,%ymm2,%ymm2
  20bfae:	vpackssdw %ymm2,%ymm3,%ymm2
  20bfb2:	vpermq $0xd8,%ymm2,%ymm2
  20bfb8:	vmovmskps %ymm2,%r9d
  20bfbc:	movzbl (%r9,%r14,1),%r12d
  20bfc1:	shl    $0x4,%r9d
  20bfc5:	vmovd  %r10d,%xmm2
  20bfca:	vpbroadcastw %xmm2,%xmm2
  20bfcf:	vpaddw (%r9,%rbx,1),%xmm2,%xmm2
  20bfd5:	vmovdqu %xmm2,(%rcx,%rax,2)
  20bfda:	add    %r12,%rax
  20bfdd:	add    $0x8,%r10
  20bfe1:	add    $0xffffffffffffffc0,%r15
  20bfe5:	jne    20bf80 <nice_common::cpu_join::pass1_avx2+0x40>
  20bfe7:	and    $0x38,%rdx
  20bfeb:	jne    20bffa <nice_common::cpu_join::pass1_avx2+0xba>
  20bfed:	jmp    20c025 <nice_common::cpu_join::pass1_avx2+0xe5>
  20bfef:	xor    %r10d,%r10d
  20bff2:	xor    %eax,%eax
  20bff4:	and    $0x38,%rdx
  20bff8:	je     20c025 <nice_common::cpu_join::pass1_avx2+0xe5>
  20bffa:	add    %r11,%rsi
  20bffd:	xor    %r9d,%r9d
  20c000:	cmp    %r8,%rax
  20c003:	jae    20c04c <nice_common::cpu_join::pass1_avx2+0x10c>
  20c005:	mov    (%rsi,%r9,1),%r11
  20c009:	and    %rdi,%r11
  20c00c:	mov    %r10w,(%rcx,%rax,2)
  20c011:	cmp    $0x1,%r11
  20c015:	adc    $0x0,%rax
  20c019:	inc    %r10d
  20c01c:	add    $0x8,%r9
  20c020:	cmp    %r9,%rdx
  20c023:	jne    20c000 <nice_common::cpu_join::pass1_avx2+0xc0>
  20c025:	add    $0x8,%rsp
  20c029:	pop    %rbx
  20c02a:	pop    %r12
  20c02c:	pop    %r14
  20c02e:	pop    %r15
  20c030:	vzeroupper
  20c033:	ret
  20c034:	lea    0x55bad(%rip),%rcx        # 261be8 <__frame_dummy_init_array_entry+0xa8c8>
  20c03b:	mov    %rax,%rdi
  20c03e:	mov    %r9,%rsi
  20c041:	mov    %r8,%rdx
  20c044:	vzeroupper
  20c047:	call   d1be0 <core::slice::index::slice_index_fail>
  20c04c:	lea    0x55b7d(%rip),%rdx        # 261bd0 <__frame_dummy_init_array_entry+0xa8b0>
  20c053:	mov    %rax,%rdi
  20c056:	mov    %r8,%rsi
  20c059:	vzeroupper
  20c05c:	call   d1cc1 <core::panicking::panic_bounds_check>
  20c061:	int3
  20c062:	int3
  20c063:	int3
  20c064:	int3
  20c065:	int3
  20c066:	int3
  20c067:	int3
  20c068:	int3
  20c069:	int3
  20c06a:	int3
  20c06b:	int3
  20c06c:	int3
  20c06d:	int3
  20c06e:	int3
  20c06f:	int3

