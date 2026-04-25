/**
 * 表单校验规则
 * 提供通用的表单验证函数
 */

/**
 * 手机号校验
 */
export function validatePhone(rule, value, callback) {
  if (!value) {
    return callback(new Error('请输入手机号'))
  }
  if (!/^1[3-9]\d{9}$/.test(value)) {
    return callback(new Error('请输入正确的手机号'))
  }
  callback()
}

/**
 * 密码校验（至少 6 位，包含字母和数字）
 */
export function validatePassword(rule, value, callback) {
  if (!value) {
    return callback(new Error('请输入密码'))
  }
  if (value.length < 6) {
    return callback(new Error('密码长度不能少于 6 位'))
  }
  if (!/[a-zA-Z]/.test(value) || !/\d/.test(value)) {
    return callback(new Error('密码需包含字母和数字'))
  }
  callback()
}

/**
 * 确认密码校验
 * @param {string} formRef - 表单引用的字段名
 */
export function validateConfirmPassword(formRef, fieldName = 'password') {
  return (rule, value, callback) => {
    if (!value) {
      return callback(new Error('请再次输入密码'))
    }
    // 通过 form 获取密码字段值进行比较
    if (formRef && formRef[fieldName] && value !== formRef[fieldName]) {
      return callback(new Error('两次输入的密码不一致'))
    }
    callback()
  }
}

/**
 * 验证码校验
 */
export function validateSmsCode(rule, value, callback) {
  if (!value) {
    return callback(new Error('请输入验证码'))
  }
  if (!/^\d{4,6}$/.test(value)) {
    return callback(new Error('验证码格式不正确'))
  }
  callback()
}

/**
 * 必填项校验
 * @param {string} label - 字段标签名
 */
export function requiredRule(label = '此项') {
  return {
    required: true,
    message: `请输入${label}`,
    trigger: 'blur'
  }
}

/**
 * 必选项校验
 * @param {string} label - 字段标签名
 */
export function requiredSelectRule(label = '此项') {
  return {
    required: true,
    message: `请选择${label}`,
    trigger: 'change'
  }
}

/**
 * 手机号校验规则（直接用于 el-form rules）
 */
export const phoneRule = {
  validator: validatePhone,
  trigger: 'blur'
}

/**
 * 密码校验规则
 */
export const passwordRule = {
  validator: validatePassword,
  trigger: 'blur'
}

/**
 * 验证码校验规则
 */
export const smsCodeRule = {
  validator: validateSmsCode,
  trigger: 'blur'
}

/**
 * 常用表单规则集合
 */
export const commonRules = {
  // 登录表单
  loginForm: {
    phone: [phoneRule],
    password: [requiredRule('密码')],
    code: [smsCodeRule]
  },
  // 注册表单
  registerForm: {
    name: [requiredRule('姓名')],
    phone: [phoneRule],
    password: [passwordRule],
    confirmPassword: [
      { validator: validateConfirmPassword(), trigger: 'blur' }
    ],
    code: [smsCodeRule],
    organization: [requiredRule('所属机构')]
  },
  // 员工表单
  employeeForm: {
    name: [requiredRule('姓名')],
    gender: [requiredSelectRule('性别')],
    birthDate: [requiredSelectRule('出生日期')],
    disabilityType: [requiredSelectRule('残疾类型')],
    guardianPhone: [phoneRule]
  },
  // 任务表单
  taskForm: {
    title: [requiredRule('任务名称')],
    description: [requiredRule('任务描述')]
  }
}
