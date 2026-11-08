000000000020be20 <nice_common::cpu_join::pass1_avx512>:
  20be20:	push   %r15
  20be22:	push   %r14
  20be24:	push   %r12
  20be26:	push   %rbx
  20be27:	push   %rax
  20be28:	shl    $0x3,%rdx
  20be2c:	mov    %edx,%r11d
  20be2f:	and    $0x3fc0,%r11d
  20be36:	je     20beb9 <nice_common::cpu_join::pass1_avx512+0x99>
  20be3c:	vpbroadcastq %rdi,%zmm0
  20be42:	xor    %r10d,%r10d
  20be45:	lea    -0x1589aa(%rip),%rbx        # b34a2 <nice_common::cpu_join::BIT_POS>
  20be4c:	lea    -0x158bc0(%rip),%r14        # b3293 <nice_common::cpu_join::BIT_CNT>
  20be53:	mov    %r11,%r15
  20be56:	xor    %eax,%eax
  20be58:	nopl   0x0(%rax,%rax,1)
  20be60:	lea    0x8(%rax),%r9
  20be64:	cmp    $0xfffffffffffffff7,%rax
  20be68:	ja     20bf04 <nice_common::cpu_join::pass1_avx512+0xe4>
  20be6e:	cmp    %r8,%r9
  20be71:	ja     20bf04 <nice_common::cpu_join::pass1_avx512+0xe4>
  20be77:	vptestnmq (%rsi,%r10,8),%zmm0,%k0
  20be7e:	kmovw  %k0,%r9d
  20be82:	movzbl %r9b,%r9d
  20be86:	movzbl (%r9,%r14,1),%r12d
  20be8b:	shl    $0x4,%r9d
  20be8f:	vmovd  %r10d,%xmm1
  20be94:	vpbroadcastw %xmm1,%xmm1
  20be99:	vpaddw (%r9,%rbx,1),%xmm1,%xmm1
  20be9f:	vmovdqu %xmm1,(%rcx,%rax,2)
  20bea4:	add    %r12,%rax
  20bea7:	add    $0x8,%r10
  20beab:	add    $0xffffffffffffffc0,%r15
  20beaf:	jne    20be60 <nice_common::cpu_join::pass1_avx512+0x40>
  20beb1:	and    $0x38,%rdx
  20beb5:	jne    20bec4 <nice_common::cpu_join::pass1_avx512+0xa4>
  20beb7:	jmp    20bef5 <nice_common::cpu_join::pass1_avx512+0xd5>
  20beb9:	xor    %eax,%eax
  20bebb:	xor    %r10d,%r10d
  20bebe:	and    $0x38,%rdx
  20bec2:	je     20bef5 <nice_common::cpu_join::pass1_avx512+0xd5>
  20bec4:	add    %r11,%rsi
  20bec7:	xor    %r9d,%r9d
  20beca:	nopw   0x0(%rax,%rax,1)
  20bed0:	cmp    %r8,%rax
  20bed3:	jae    20bf1c <nice_common::cpu_join::pass1_avx512+0xfc>
  20bed5:	mov    (%rsi,%r9,1),%r11
  20bed9:	and    %rdi,%r11
  20bedc:	mov    %r10w,(%rcx,%rax,2)
  20bee1:	cmp    $0x1,%r11
  20bee5:	adc    $0x0,%rax
  20bee9:	inc    %r10d
  20beec:	add    $0x8,%r9
  20bef0:	cmp    %r9,%rdx
  20bef3:	jne    20bed0 <nice_common::cpu_join::pass1_avx512+0xb0>
  20bef5:	add    $0x8,%rsp
  20bef9:	pop    %rbx
  20befa:	pop    %r12
  20befc:	pop    %r14
  20befe:	pop    %r15
  20bf00:	vzeroupper
  20bf03:	ret
  20bf04:	lea    0x55cdd(%rip),%rcx        # 261be8 <__frame_dummy_init_array_entry+0xa8c8>
  20bf0b:	mov    %rax,%rdi
  20bf0e:	mov    %r9,%rsi
  20bf11:	mov    %r8,%rdx
  20bf14:	vzeroupper
  20bf17:	call   d1be0 <core::slice::index::slice_index_fail>
  20bf1c:	lea    0x55cad(%rip),%rdx        # 261bd0 <__frame_dummy_init_array_entry+0xa8b0>
  20bf23:	mov    %rax,%rdi
  20bf26:	mov    %r8,%rsi
  20bf29:	vzeroupper
  20bf2c:	call   d1cc1 <core::panicking::panic_bounds_check>
  20bf31:	int3
  20bf32:	int3
  20bf33:	int3
  20bf34:	int3
  20bf35:	int3
  20bf36:	int3
  20bf37:	int3
  20bf38:	int3
  20bf39:	int3
  20bf3a:	int3
  20bf3b:	int3
  20bf3c:	int3
  20bf3d:	int3
  20bf3e:	int3
  20bf3f:	int3

